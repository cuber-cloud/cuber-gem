module Cuber::Commands
  class Deploy
    include Cuber::Utils

    def initialize options
      @options = options
    end

    def execute
      mktmpdirs
      if @options[:release]
        print_step 'Deploying a past release'
      else
        checkout
        set_release_name
        if @options[:buildpacks]
          pack
        else
          build
          push
        end
      end
      configure
      apply
      rollout
    ensure
      rmtmpdirs
    end

    private
    
    def mktmpdirs
      @repo_tmpdir = Dir.mktmpdir
      @kubernetes_tmpdir = Dir.mktmpdir
    end
    
    def rmtmpdirs
      FileUtils.remove_entry @repo_tmpdir
      FileUtils.remove_entry @kubernetes_tmpdir
    end

    def print_step desc
      puts
      puts "\e[34m-----> #{desc}\e[0m"
    end

    def checkout
      print_step 'Cloning Git repository'
      cmd = ['git', 'clone']
      cmd += ['--branch', @options[:repo][:branch]] if @options[:repo][:branch]
      cmd += ['--depth', '1', @options[:repo][:url], @repo_tmpdir]
      system(*cmd) || abort('Cuber: git clone failed')
    end

    def commit_hash
      out, status = Open3.capture2 'git', 'rev-parse', '--short', 'HEAD', chdir: @repo_tmpdir
      abort 'Cuber: cannot get commit hash' unless status.success?
      out.strip
    end

    def set_release_name
      @options[:release] = "#{commit_hash}-#{Time.now.utc.iso8601.delete('^0-9')}"
    end

    def pack
      print_step 'Building image using buildpacks'
      tag = "#{@options[:image]}:#{@options[:release]}"
      cmd = ['pack', 'build', tag, '--builder', @options[:buildpacks], '--publish']
      cmd += ['--pull-policy', 'always', '--clear-cache'] if @options[:cache] == false
      system(*cmd, chdir: @repo_tmpdir) || abort('Cuber: pack build failed')
    end

    def build
      print_step 'Building image from Dockerfile'
      dockerfile = @options[:dockerfile] || 'Dockerfile'
      tag = "#{@options[:image]}:#{@options[:release]}"
      cmd = ['docker', 'build']
      cmd += ['--pull', '--no-cache'] if @options[:cache] == false
      cmd += ['--platform', 'linux/amd64', '--progress', 'plain', '-f', dockerfile, '-t', tag, '.']
      system(*cmd, chdir: @repo_tmpdir) || abort('Cuber: docker build failed')
    end

    def push
      print_step 'Pushing image to Docker registry'
      tag = "#{@options[:image]}:#{@options[:release]}"
      system('docker', 'push', tag) || abort('Cuber: docker push failed')
    end

    def configure
      print_step 'Generating Kubernetes configuration'
      @options[:instance] = "#{@options[:app]}-#{Time.now.utc.iso8601.delete('^0-9')}"
      @options[:dockerconfigjson] = Base64.strict_encode64 File.read File.expand_path(@options[:dockerconfig] || '~/.docker/config.json')
      render 'deployment.yml', File.join(@kubernetes_tmpdir, 'deployment.yml')
    end

    def apply
      print_step 'Applying configuration to Kubernetes cluster'
      kubectl 'apply',
        '-f', File.join(@kubernetes_tmpdir, 'deployment.yml'),
        '--prune', '-l', "app.kubernetes.io/name=#{@options[:app]},app.kubernetes.io/managed-by=cuber"
    end

    def rollout
      print_step 'Verifying deployment status'
      @options[:procs].each_key do |procname|
        kubectl 'rollout', 'status', "deployment/#{procname}"
      end
    end

  end
end
