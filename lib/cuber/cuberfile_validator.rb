module Cuber
  class CuberfileValidator

    def initialize options
      @options = options
      @errors = []
    end

    def validate
      validate_app
      validate_release
      validate_repo
      validate_buildpacks
      validate_dockerfile
      validate_image
      validate_cache
      validate_dockerconfig
      validate_kubeconfig
      validate_migrate
      validate_procs
      validate_cron
      validate_env
      validate_health
      validate_lb
      validate_ingress
      validate_ssl
      @errors
    end

    private

    def validate_app
      @errors << 'app name must be present' if @options[:app].to_s.strip.empty?
      @errors << 'app name can only include lowercase letters, digits or dashes' if @options[:app] !~ /\A[a-z0-9\-]+\z/
    end

    def validate_release
      return unless @options[:release]
      @errors << 'release has an invalid format' if @options[:release] !~ /\A[a-zA-Z0-9_\-\.]+\z/
    end

    def validate_repo
      @errors << 'repo must be present' if @options[:repo].nil? || @options[:repo][:url].to_s.strip.empty?
    end

    def validate_buildpacks
      return unless @options[:buildpacks]
      @errors << 'buildpacks is not compatible with the dockerfile option' if @options[:dockerfile]
    end

    def validate_dockerfile
      return unless @options[:dockerfile]
      @errors << 'dockerfile must be a file' unless File.exist? @options[:dockerfile]
    end

    def validate_image
      @errors << 'image must be present' if @options[:image].to_s.strip.empty?
    end

    def validate_cache
      return unless @options[:cache]
      @errors << 'cache must be true or false' if @options[:cache] != true && @options[:cache] != false
    end

    def validate_dockerconfig
      return unless @options[:dockerconfig]
      @errors << 'dockerconfig must be a file' unless File.exist? @options[:dockerconfig]
    end

    def validate_kubeconfig
      @errors << 'kubeconfig must be present' if @options[:kubeconfig].to_s.strip.empty?
      @errors << 'kubeconfig must be a file' unless File.exist? @options[:kubeconfig]
    end

    def validate_migrate
      return unless @options[:migrate]
      @errors << 'migrate command must be present' if @options[:migrate][:cmd].to_s.strip.empty?
    end

    def validate_procs
      @options[:procs].each do |procname, proc|
        @errors << "proc \"#{procname}\" name can only include lowercase letters" if procname !~ /\A[a-z]+\z/
        @errors << "proc \"#{procname}\" command must be present" if proc[:cmd].to_s.strip.empty?
        @errors << "proc \"#{procname}\" scale must be a positive number" unless proc[:scale].is_a?(Integer) && proc[:scale] > 0
        @errors << "proc \"#{procname}\" cpu must be a positive number" unless proc[:cpu].nil? || proc[:cpu].is_a?(Numeric) && proc[:cpu] > 0
        @errors << "proc \"#{procname}\" ram must be a positive number" unless proc[:ram].nil? || proc[:ram].is_a?(Numeric) && proc[:ram] > 0  
        @errors << "proc \"#{procname}\" term must be a positive number" unless proc[:term].is_a?(Integer) && proc[:term] > 0
        proc[:env].each do |key, value|
          @errors << "proc \"#{procname}\" env name can only include uppercase letters, digits or underscores" if key !~ /\A[A-Z_]+[A-Z0-9_]*\z/
        end
      end
    end

    def validate_cron
      @options[:cron].each do |jobname, cron|
        @errors << "cron \"#{jobname}\" name can only include lowercase letters" if jobname !~ /\A[a-z]+\z/
        @errors << "cron \"#{jobname}\" schedule must be present" if cron[:schedule].to_s.strip.empty?
        @errors << "cron \"#{jobname}\" command must be present" if cron[:cmd].to_s.strip.empty?
      end
    end

    def validate_env
      @options[:env].merge(@options[:secrets]).each do |key, value|
        @errors << "env \"#{key}\" name can only include uppercase letters, digits or underscores" if key !~ /\A[A-Z_]+[A-Z0-9_]*\z/
      end
    end
    
    def validate_health
      return unless @options[:health]
      @errors << 'health checks must be an http url' unless URI.parse(@options[:health]).kind_of? URI::HTTP
    end

    def validate_lb
      @options[:lb].each do |key, value|
        @errors << "lb \"#{key}\" key can only include letters, digits, underscores, dashes, dots or slash" if key !~ /\A[a-zA-Z0-9_\-\.\/]+\z/
      end
    end

    def validate_ingress
      return unless @options[:ingress]
      @errors << 'ingress must be true or false' if @options[:ingress] != true && @options[:ingress] != false
    end

    def validate_ssl
      return unless @options[:ssl]
      @errors << 'ssl crt must be a file' unless File.exist? @options[:ssl][:crt]
      @errors << 'ssl key must be a file' unless File.exist? @options[:ssl][:key]
    end

  end
end
