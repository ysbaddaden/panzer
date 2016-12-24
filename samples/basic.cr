require "../src/monitor"

class MyWorker
  include Panzer::Worker

  def initialize
    logger.debug { "initializing (#{Process.pid})" }
  end

  def run
    logger.progname = "panzer:worker"
    logger.debug { "running (#{Process.pid})" }

    loop do
      sleep #rand(2..10)
      break
    end

    logger.debug { "exiting: (#{Process.pid})" }
  end
end

Panzer.logger.progname = "panzer:monitor"
Panzer.logger.level = Logger::Severity::DEBUG

Panzer::Monitor.run(MyWorker.new, count: 8)
