module Cuber::Commands
  class Run
    include Cuber::Utils

    def initialize options
      @options = options
    end

    def execute
      set_current_release
      kubeexec command
    end

    private

    def set_current_release
      json = kubeget 'namespace', @options[:app]
      @options[:app] = json['metadata']['labels']['app.kubernetes.io/name']
      @options[:release] = json['metadata']['labels']['app.kubernetes.io/version']
      @options[:image] = json['metadata']['annotations']['image']
      @options[:buildpacks] = json['metadata']['annotations']['buildpacks']
    end

    def command
      if ARGV.length == 0
        'sh'
      elsif ARGV.length == 1
        ARGV.first
      else
        ARGV.shelljoin
      end
    end

    def kubeexec command
      @options[:pod] = "pod-#{command.downcase.gsub(/[^a-z0-9]+/, '-')}-#{Time.now.utc.iso8601.delete('^0-9')}"
      path = ".cuber/kubernetes/#{@options[:pod]}.yml"
      full_command = command.shellsplit
      full_command.unshift 'launcher' unless @options[:buildpacks].to_s.strip.empty?
      render 'pod.yml', path
      kubectl 'apply', '-f', path
      kubectl 'wait', '--for', 'condition=ready', "pod/#{@options[:pod]}"
      kubectl 'exec', '-it', @options[:pod], '--', *full_command
      kubectl 'delete', 'pod', @options[:pod], '--wait=false'
      File.delete path
    end

  end
end
