module Cuber::Commands
  class Version

    def execute
      puts "Cuber v#{Cuber::VERSION}"
    end

  end
end
