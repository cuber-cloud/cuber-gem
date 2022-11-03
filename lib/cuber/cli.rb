require 'optparse'
require 'fileutils'
require 'open3'
require 'erb'
require 'base64'
require 'yaml'
require 'json'
require 'shellwords'
require 'time'
require 'uri'

module Cuber
  class CLI

    def initialize
      @options = {}
      parse_command!
      parse_cuberfile
      validate_cuberfile
      execute
    end

    private

    def parse_command!
      @options[:cmd] = ARGV.shift&.to_sym
    end

    def parse_cuberfile
      abort 'Cuberfile not found in current directory' unless File.exist? 'Cuberfile'
      content = File.read 'Cuberfile'
      parser = CuberfileParser.new
      parser.instance_eval(content)
      cuberfile_options = parser.instance_variables.map do |name|
        [name[1..-1].to_sym, parser.instance_variable_get(name)]
      end.to_h
      @options.merge! cuberfile_options
    end

    def validate_cuberfile
      validator = CuberfileValidator.new @options
      errors = validator.validate
      errors.each { |err| $stderr.puts "Cuberfile: #{err}" }
      abort unless errors.empty?
    end

    def execute
      command_class = @options[:cmd]&.capitalize
      abort "Cuber: \"#{@options[:cmd]}\" is not a command" unless command_class && Cuber::Commands.const_defined?(command_class)
      Cuber::Commands.const_get(command_class).new(@options).execute
    end

  end
end
