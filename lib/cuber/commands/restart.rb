module Cuber::Commands
  class Restart
    include Cuber::Utils

    def initialize options
      @options = options
    end

    def execute
      kubectl 'rollout', 'restart', 'deploy'
    end

  end
end
