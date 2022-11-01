module Cuber::Commands
  class Ctl
    include Cuber::Utils

    def initialize options
      @options = options
    end

    def execute
      kubectl *ARGV
    end

  end
end
