require "./process"

module Panzer
  class MonitorProcess
    @process : Process
    @timeout : Time::Span

    def initialize(command, @timeout = 60.seconds)
      @process = fork do
        Process.exec(command)
      end
      @sigint = 0
      logger.info { "spawned monitor #{pid}" }
    end

    def pid
      @process.pid
    end

    def logger
      Panzer.logger
    end

    def exit
      terminate

      begin
        Process.wait(pid, @timeout)
      rescue Timeout::Error
        kill
      end

      logger.info { "monitor #{pid} exited" }
    end

    def terminate
      logger.debug { "terminating monitor #{pid}" }
      Process.kill(Signal::TERM, pid)
    end

    def interrupt
      case @sigint += 1
      when 1 then self.exit
      when 2 then self.kill
      end
    end

    def kill
      logger.debug { "killing monitor #{pid}" }
      Process.kill(Signal::KILL, pid)
    end

    def running?
      Process.running?(pid)
    end
  end
end
