require 'optparse'

module Cuber
  class CLI

    def initialize
      parse_options!
      cmd = ARGV.first&.to_sym
      abort "\"#{cmd}\" is not a command" unless cmd and respond_to? cmd
      public_send cmd
    end

    def version
      puts "Cuber v#{Cuber::VERSION}"
    end

    private

    def parse_options!
      @options = {}
      OptionParser.new do |opts|
        opts.banner = 'Usage: cuber [OPTIONS] COMMAND'
        opts.on('-e', '--environment ENVIRONMENT', 'Set the environment (e.g. production)') do |e|
          @options[:environment] = e
        end
      end.parse!
    end

  end
end
