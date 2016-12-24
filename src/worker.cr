module Panzer
  module Worker
    abstract def run

    def spawn
      process = fork do
        Signal::CHLD.reset
        Signal::TERM.reset
        Signal::INT.reset
        Signal::TTIN.reset
        run
      end
      logger.info { "started worker (#{process.pid})" }
      process
    end

    def logger
      Panzer.logger
    end
  end
end
