require 'optparse'
require 'fileutils'
require 'open3'
require 'erb'
require 'base64'
require 'yaml'
require 'json'
require 'shellwords'
require 'time'

module Cuber
  class CLI

    def initialize
      @options = {}
      parse_options!
      parse_command!
      parse_cuberfile
      validate_options
      execute
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

    def parse_command!
      @options[:cmd] = ARGV.shift&.to_sym
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
      abort 'Cuberfile: app must be present' if @options[:app].to_s.strip.empty?
      abort 'Cuberfile: repo must be present' if @options[:repo].to_s.strip.empty?
      abort 'Cuberfile: dockerfile must be a file' unless @options[:dockerfile].nil? or File.exists? @options[:dockerfile]
      abort 'Cuberfile: ruby version must be present' if @options[:ruby].to_s.strip.empty?
      abort 'Cuberfile: image must be present' if @options[:image].to_s.strip.empty?
      abort 'Cuberfile: dockerconfig must be a file' unless @options[:dockerconfig].nil? or File.exists? @options[:dockerconfig]
      abort 'Cuberfile: kubeconfig must be present' if @options[:kubeconfig].to_s.strip.empty?
      abort 'Cuberfile: proc invalid format' if @options[:procs].any? { |key, value| key !~ /\A[a-z]+\z/ }
      abort 'Cuberfile: cron invalid format' if @options[:cron].any? { |key, value| key !~ /\A[a-z]+\z/ }
      abort 'Cuberfile: env invalid format' if @options[:env].merge(@options[:secrets]).any? { |key, value| key !~ /\A[a-zA-Z_]+[a-zA-Z0-9_]*\z/ }
    end

    def execute
      command_class = @options[:cmd]&.capitalize
      abort "Cuber: \"#{@options[:cmd]}\" is not a command" unless command_class && Cuber::Commands.const_defined?(command_class)
      Cuber::Commands.const_get(command_class).new(@options).execute
    end

  end
end
