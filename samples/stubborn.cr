require "../src/monitor"

class StubbornWorker
  include Panzer::Worker

  def run
    Panzer.logger.progname = "panzer:worker"

    Signal::TERM.trap do
      logger.warn { "Received SIGTERM, but I won't die that easily!" }
    end

    Signal::INT.trap do
      logger.warn { "okay, I give up" }
    end

    sleep # forever
  end
end

Panzer.logger.progname = "panzer:monitor"
Panzer.logger.level = Logger::Severity::DEBUG

Panzer::Monitor.run(StubbornWorker.new, count: 1, timeout: 2.seconds)
