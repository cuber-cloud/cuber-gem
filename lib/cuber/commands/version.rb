module Cuber::Commands
  class Version

    def initialize options
      @options = options
    end

    def execute
      puts "Cuber v#{Cuber::VERSION}"
    end

  end
end
