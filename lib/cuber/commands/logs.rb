module Cuber::Commands
  class Logs
    include Cuber::Utils

    def initialize options
      @options = options
    end

    def execute
      pod = ARGV.first
      cmd = ['logs']
      cmd += pod ? [pod] : ['-l', "app.kubernetes.io/name=#{@options[:app]}"]
      cmd += ['--all-containers']
      kubectl *cmd
    end

  end
end
