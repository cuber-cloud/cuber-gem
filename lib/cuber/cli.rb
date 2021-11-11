require 'optparse'
require 'fileutils'
require 'open3'
require 'erb'
require 'base64'
require 'json'
require 'shellwords'
require 'time'

module Cuber
  class CLI

    def initialize
      @options = {}
      parse_options!
      parse_cuberfile
      @options[:cmd] = ARGV.shift&.to_sym
      validate_options
      public_send @options[:cmd]
    end

    def version
      puts "Cuber v#{Cuber::VERSION}"
    end

    def info
      json = kubeget 'namespace', @options[:app]
      puts "App: #{json['metadata']['labels']['app.kubernetes.io/name']}"
      puts "Version: #{json['metadata']['labels']['app.kubernetes.io/version']}"

      json = kubeget 'service', 'load-balancer'
      puts "Public IP: #{json['status']['loadBalancer']['ingress'][0]['ip']}"

      puts "Env:"

      json = kubeget 'configmap', 'env'
      json['data'].each do |key, value|
        puts "  #{key}=#{value}"
      end

      json = kubeget 'secrets', 'app-secrets'
      json['data'].each do |key, value|
        puts "  #{key}=#{Base64.decode64(value)[0...5] + '***'}"
      end

      puts "Proc:"

      json = kubeget 'deployments'
      json['items'].each do |proc|
        name = proc['metadata']['name'].delete_suffix('-deployment')
        command = proc['spec']['template']['spec']['containers'][0]['command'].shelljoin
        available = proc['status']['availableReplicas']
        scale = proc['spec']['replicas']
        puts "  #{name}: #{command} (#{available}/#{scale})"
      end
    end

    def logs
      kubectl 'logs',
        '-l', "app.kubernetes.io/name=#{@options[:app]}",
        '--tail', '100'
    end

    def sh
      @options[:shell] = "shell-#{Time.now.utc.iso8601.delete('^0-9')}"

      json = kubeget 'namespace', @options[:app]
      @options[:app] = json['metadata']['labels']['app.kubernetes.io/name']
      @options[:release] = json['metadata']['labels']['app.kubernetes.io/version']
      @options[:image] = json['metadata']['annotations']['image']

      path = ".cuber/kubernetes/#{@options[:shell]}.yml"
      render 'shell.yml', path

      kubectl 'apply', '-f', path
      kubectl 'wait', '--for', 'condition=ready', "pod/#{@options[:shell]}"
      kubectl 'exec', '-it', @options[:shell], '--', '/bin/sh'
      kubectl 'delete', 'pod', @options[:shell], '--wait=false'

      File.delete path
    end

    def run
      @options[:job] = "job-#{Time.now.utc.iso8601.delete('^0-9')}"
      @options[:job_cmd] = ARGV

      json = kubeget 'namespace', @options[:app]
      @options[:app] = json['metadata']['labels']['app.kubernetes.io/name']
      @options[:release] = json['metadata']['labels']['app.kubernetes.io/version']
      @options[:image] = json['metadata']['annotations']['image']

      path = ".cuber/kubernetes/#{@options[:job]}.yml"
      render 'job.yml', path
      kubectl 'apply', '-f', path
      File.delete path

      loop do
        json = kubeget 'job', @options[:job]
        break if json['status']['active'].to_i.zero?
        sleep 1
      end

      kubectl 'logs', '-l', "job-name=#{@options[:job]}", '--tail=-1'
    end

    def deploy
      checkout
      set_release_name
      dockerfile
      build
      push
      configure
      apply
      rollout
    end

    private

    def checkout
      print_step 'Cloning Git repository'
      path = '.cuber/repo'
      FileUtils.mkdir_p path
      FileUtils.rm_rf path, secure: true
      system('git', 'clone', '--depth', '1', @options[:repo], path) || abort('Cuber: git clone failed')
    end

    def dockerfile
      print_step 'Generating Dockerfile'
      return if @options[:dockerfile]
      render 'Dockerfile', '.cuber/repo/Dockerfile'
    end

    def build
      print_step 'Building image from Dockerfile'
      dockerfile = @options[:dockerfile] || 'Dockerfile'
      tag = "#{@options[:image]}:#{@options[:release]}"
      system('docker', 'build', '--pull', '--no-cache', '-f', dockerfile, '-t', tag, '.', chdir: '.cuber/repo') || abort('Cuber: docker build failed')
    end

    def push
      print_step 'Pushing image to Docker registry'
      tag = "#{@options[:image]}:#{@options[:release]}"
      system('docker', 'push', tag) || abort('Cuber: docker push failed')
    end

    def configure
      print_step 'Generating Kubernetes configuration'
      @options[:dockerconfigjson] = Base64.strict_encode64 File.read File.expand_path(@options[:dockerconfig] || '~/.docker/config.json')
      render 'deployment.yml', '.cuber/kubernetes/deployment.yml'
    end

    def apply
      print_step 'Applying configuration to Kubernetes cluster'
      kubectl 'apply',
        '-f', '.cuber/kubernetes/deployment.yml',
        '--prune', '-l', "app.kubernetes.io/name=#{@options[:app]},app.kubernetes.io/managed-by=cuber"
    end

    def rollout
      print_step 'Verifying deployment status'
      @options[:procs].each_key do |procname|
        kubectl 'rollout', 'status', "deployment/#{procname}-deployment"
      end
    end

    def parse_options!
      OptionParser.new do |opts|
        opts.banner = 'Usage: cuber [OPTIONS] COMMAND'
        opts.on('-e', '--environment ENVIRONMENT', 'Set the environment (e.g. production)') do |e|
          @options[:environment] = e
        end
      end.parse!
    end

    def parse_cuberfile
      abort 'Cuberfile not found in current directory' unless File.exists? 'Cuberfile'
      content = File.read 'Cuberfile'
      parser = CuberfileParser.new
      parser.instance_eval(content)
      cuberfile_options = parser.instance_variables.map do |name|
        [name[1..-1].to_sym, parser.instance_variable_get(name)]
      end.to_h
      @options.merge! cuberfile_options
    end

    def validate_options
      abort "Cuber: \"#{@options[:cmd]}\" is not a command" unless @options[:cmd] and respond_to? @options[:cmd]
      abort 'Cuberfile: app must be present' if @options[:app].to_s.strip.empty?
      abort 'Cuberfile: repo must be present' if @options[:repo].to_s.strip.empty?
      abort 'Cuberfile: dockerfile must be a file' unless @options[:dockerfile].nil? or File.exists? @options[:dockerfile]
      abort 'Cuberfile: ruby version must be present' if @options[:ruby].to_s.strip.empty?
      abort 'Cuberfile: image must be present' if @options[:image].to_s.strip.empty?
      abort 'Cuberfile: dockerconfig must be a file' unless @options[:dockerconfig].nil? or File.exists? @options[:dockerconfig]
      abort 'Cuberfile: kubeconfig must be present' if @options[:kubeconfig].to_s.strip.empty?
      abort 'Cuberfile: proc invalid format' if @options[:procs].any? { |key, value| key !~ /\A[a-z]+\z/ }
      abort 'Cuberfile: env invalid format' if @options[:env].merge(@options[:secrets]).any? { |key, value| key !~ /\A[a-zA-Z_]+[a-zA-Z0-9_]*\z/ }
    end

    def commit_hash
      out, status = Open3.capture2 'git', 'rev-parse', '--short', 'HEAD', chdir: '.cuber/repo'
      abort 'Cuber: cannot get commit hash' unless status.success?
      out.strip
    end

    def set_release_name
      @options[:release] = "#{commit_hash}-#{Time.now.utc.iso8601.delete('^0-9')}"
    end

    def kubectl *args
      cmd = ['kubectl', '--kubeconfig', @options[:kubeconfig], '-n', @options[:app]] + args
      system(*cmd) || abort("Cuber: \"#{cmd.shelljoin}\" failed")
    end

    def kubeget type, name = nil
      cmd = ['kubectl', 'get', type, name, '-o', 'json', '--kubeconfig', @options[:kubeconfig], '-n', @options[:app]].compact
      out, status = Open3.capture2 *cmd
      abort 'Cuber: kubectl get failed' unless status.success?
      JSON.parse(out)
    end

    def render template, target_file = nil
      template = File.join __dir__, 'templates', "#{template}.erb"
      renderer = ERB.new File.read(template), trim_mode: '-'
      content = renderer.result binding
      return content unless target_file
      FileUtils.mkdir_p File.dirname target_file
      File.write target_file, content
    end

    def print_step desc
      puts
      puts "\e[34m-----> #{desc}\e[0m"
    end

  end
end
