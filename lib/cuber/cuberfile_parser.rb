module Cuber
  class CuberfileParser
    def initialize
      @app = nil
      @release = nil
      @repo = nil
      @buildpacks = nil
      @dockerfile = nil
      @image = nil
      @cache = nil
      @dockerconfig = nil
      @kubeconfig = nil
      @migrate = nil
      @procs = {}
      @cron = {}
      @secrets = {}
      @env = {}
    end

    def method_missing m, *args
      abort "Cuberfile: \"#{m}\" is not a command"
    end

    def app name
      @app = name
    end

    def release version
      @release = version
    end

    def repo uri
      @repo = uri
    end

    def buildpacks builder
      @buildpacks = builder
    end

    def dockerfile path
      @dockerfile = path
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

    def migrate cmd, check: nil
      @migrate = { cmd: cmd, check: check }
    end

    def proc name, cmd, scale: 1
      @procs[name] = { cmd: cmd, scale: scale }
    end

    def cron name, schedule, cmd
      @cron[name] = { schedule: schedule, cmd: cmd }
    end

    def env key, value, secret: false
      secret ? (@secrets[key] = value) : (@env[key] = value)
    end
  end
end
