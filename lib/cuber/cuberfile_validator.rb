module Cuber
  class CuberfileValidator

    def initialize options
      @options = options
      @errors = []
    end

    def validate
      @errors << 'app must be present' if @options[:app].to_s.strip.empty?
      @errors << 'repo must be present' if @options[:repo].to_s.strip.empty?
      @errors << 'dockerfile must be a file' unless @options[:dockerfile].nil? or File.exists? @options[:dockerfile]
      @errors << 'ruby version must be present' if @options[:ruby].to_s.strip.empty?
      @errors << 'image must be present' if @options[:image].to_s.strip.empty?
      @errors << 'dockerconfig must be a file' unless @options[:dockerconfig].nil? or File.exists? @options[:dockerconfig]
      @errors << 'kubeconfig must be present' if @options[:kubeconfig].to_s.strip.empty?
      @errors << 'proc invalid format' if @options[:procs].any? { |key, value| key !~ /\A[a-z]+\z/ }
      @errors << 'cron invalid format' if @options[:cron].any? { |key, value| key !~ /\A[a-z]+\z/ }
      @errors << 'env invalid format' if @options[:env].merge(@options[:secrets]).any? { |key, value| key !~ /\A[a-zA-Z_]+[a-zA-Z0-9_]*\z/ }
      @errors
    end

  end
end
