require "mutex"
require "./monitor_process"
require "./logger"

module Panzer
  def self.run(command)
    mutex = Mutex.new
    old_monitor = nil
    monitor = Panzer::MonitorProcess.new(command)

    # Restart application.
    Signal::USR1.trap do
      old_monitor, monitor = monitor, Panzer::MonitorProcess.new(command)
    end

    # Application started: exit previous application
    Signal::VTALRM.trap do
      old_monitor.try(&.exit)
    end

    # Exit gracefully
    Signal::TERM.trap do
      monitor.terminate
      exit 0
    end

    # Exit quickly.
    Signal::INT.trap do
      monitor.interrupt
      exit 0
    end

    # Application failed or previous application exited.
    Signal::CHLD.trap do
      mutex.synchronize do
        unless monitor.running?
          Panzer.logger.error { "monitor #{monitor.pid} exited" }
          monitor = Panzer::MonitorProcess.new(command)
        end
      end

      if old_monitor
        old_monitor = nil
      end
    end

    sleep # forever
  end
end

# TODO: OptionParser

Panzer.logger.progname = "panzer:main"
Panzer.logger.level = Logger::Severity::DEBUG
Panzer.run(command: ARGV[0])
