require 'optparse'

module Cuber
  class CLI

    def initialize
      @options = {}
      parse_options!
      parse_cuberfile
      cmd = ARGV.first&.to_sym
      abort "Cuber: \"#{cmd}\" is not a command" unless cmd and respond_to? cmd
      public_send cmd
    end

    def version
      puts "Cuber v#{Cuber::VERSION}"
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
      content = File.read('Cuberfile')
      parser = CuberfileParser.new
      parser.instance_eval(content)
      cuberfile_options = parser.instance_variables.map do |name|
        [name[1..-1].to_sym, parser.instance_variable_get(name)]
      end.to_h
      @options.merge! cuberfile_options
    end

  end
end
