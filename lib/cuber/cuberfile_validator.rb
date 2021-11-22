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
      @errors << 'repo must be present' if @options[:repo].to_s.strip.empty?
    end

    def validate_buildpacks
      return unless @options[:buildpacks]
      @errors << 'buildpacks is not compatible with the dockerfile option' if @options[:dockerfile]
    end

    def validate_dockerfile
      return unless @options[:dockerfile]
      @errors << 'dockerfile must be a file' unless File.exists? @options[:dockerfile]
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
      @errors << 'dockerconfig must be a file' unless File.exists? @options[:dockerconfig]
    end

    def validate_kubeconfig
      @errors << 'kubeconfig must be present' if @options[:kubeconfig].to_s.strip.empty?
      @errors << 'kubeconfig must be a file' unless File.exists? @options[:kubeconfig]
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

  end
end
