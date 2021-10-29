require 'optparse'
require 'fileutils'

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

    def validate_options
      abort "Cuber: \"#{@options[:cmd]}\" is not a command" unless @options[:cmd] and respond_to? @options[:cmd]
      abort 'Cuberfile: repo must be present' if @options[:repo].to_s.strip.empty?
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

  end
end
