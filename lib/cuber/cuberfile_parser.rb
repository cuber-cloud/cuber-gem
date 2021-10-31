module Cuber
  class CuberfileParser
    def initialize
      @app = nil
      @repo = nil
      @dockerfile = nil
      @ruby = nil
      @image = nil
      @procs = []
    end

    def method_missing m
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

    def proc name, replicas = 1
      @procs << { name: name, replicas: replicas }
    end
  end
end
