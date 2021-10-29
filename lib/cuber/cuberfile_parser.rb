module Cuber
  class CuberfileParser
    def initialize
      @app = nil
      @repo = nil
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

    def proc name, replicas = 1
      @procs << { name: name, replicas: replicas }
    end
  end
end
