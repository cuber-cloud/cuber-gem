require 'optparse'
require 'fileutils'
require 'open3'
require 'erb'
require 'base64'
require 'json'
require 'shellwords'

module Cuber
  class CLI

    def initialize
      @options = {}
      parse_options!
      parse_cuberfile
      @options[:cmd] = ARGV.first&.to_sym
      validate_options
      public_send @options[:cmd]
    end

    def version
      puts "Cuber v#{Cuber::VERSION}"
    end

    def checkout
      path = '.cuber/repo'
      FileUtils.mkdir_p path
      FileUtils.rm_rf path, secure: true
      system('git', 'clone', '--depth', '1', @options[:repo], path) || abort('Cuber: git clone failed')
    end

    def dockerfile
      return if @options[:dockerfile]
      template = File.join __dir__, 'templates', 'Dockerfile.erb'
      renderer = ERB.new File.read template
      content = renderer.result binding
      path = '.cuber/repo'
      FileUtils.mkdir_p path
      File.write File.join(path, 'Dockerfile'), content
    end

    def build
      dockerfile = @options[:dockerfile] || 'Dockerfile'
      tag = "#{@options[:image]}:#{commit_hash}"
      system('docker', 'build', '-f', dockerfile, '-t', tag, '.', chdir: '.cuber/repo') || abort('Cuber: docker build failed')
    end

    def push
      tag = "#{@options[:image]}:#{commit_hash}"
      system('docker', 'push', tag) || abort('Cuber: docker push failed')
    end

    def configure
      @options[:commit_hash] = commit_hash
      @options[:dockerconfigjson] = Base64.strict_encode64 File.read File.expand_path(@options[:dockerconfig] || '~/.docker/config.json')
      template = File.join __dir__, 'templates', 'deployment.yml.erb'
      renderer = ERB.new File.read template
      content = renderer.result binding
      path = '.cuber/kubernetes'
      FileUtils.mkdir_p path
      File.write File.join(path, 'deployment.yml'), content
    end

    def deploy
      cmd = ['kubectl', 'apply',
        '--kubeconfig', @options[:kubeconfig],
        '-n', @options[:app],
        '-f', '.cuber/kubernetes/deployment.yml',
        '--prune', '-l', "app.kubernetes.io/name=#{@options[:app]},app.kubernetes.io/managed-by=cuber"]
      system(*cmd) || abort('Cuber: kubectl apply failed')
    end

    private

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
      abort 'Cuberfile: env invalid format' if @options.any? { |key, value| key !~ /\A[a-zA-Z_]+[a-zA-Z0-9_]*\z/ }
    end

    def commit_hash
      out, status = Open3.capture2 'git', 'rev-parse', 'HEAD', chdir: '.cuber/repo'
      abort 'Cuber: cannot get commit hash' unless status.success?
      out.strip
    end

  end
end
