module Cuber
  class CuberfileParser
    def initialize
      @app = nil
      @repo = nil
      @dockerfile = nil
      @ruby = nil
      @image = nil
      @cache = nil
      @dockerconfig = nil
      @kubeconfig = nil
      @procs = {}
      @secrets = {}
      @env = {}
    end

    def method_missing m, *args
      abort "Cuberfile: \"#{m}\" is not a command"
    end

    def app name
      @app = name
    end

    def repo uri
      @repo = uri
    end

    def dockerfile path
      @dockerfile = path
    end

    def ruby version
      @ruby = version
    end

    def image name
      @image = name
    end

    def cache enabled
      @cache = enabled
    end

    def dockerconfig path
      @dockerconfig = path
    end

    def kubeconfig path
      @kubeconfig = path
    end

    def proc name, cmd, scale: 1
      @procs[name] = { cmd: cmd, scale: scale }
    end

    def env key, value, secret: false
      secret ? (@secrets[key] = value) : (@env[key] = value)
    end
  end
end
