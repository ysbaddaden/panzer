require "mutex"
require "./logger"
require "./process"
require "./worker"

module Panzer
  class Monitor
    def self.run(worker, count, timeout = 60.seconds)
      monitor = new(worker, count, timeout)
      monitor.fill

      # Collect zombie worker, refill worker pool
      Signal::CHLD.trap do
        monitor.collect
        monitor.fill
      end

      # Exit gracefully.
      Signal::TERM.trap do
        monitor.terminate
        exit 0
      end

      # Exit gracefully.
      Signal::INT.trap do
        monitor.terminate
        exit 0
      end

      # TODO: Print worker status
      #Signal::TTIN.trap do
      #end

      # Notify parent process that we are running.
      Process.kill(Signal::VTALRM, Process.ppid)

      sleep # forever
    end

    getter worker : Worker
    getter count : Int32
    getter timeout : Time::Span

    def initialize(@worker, @count, @timeout = 60.seconds)
      @pool = [] of LibC::PidT
      @mutex = Mutex.new
      @exiting = false
    end

    def logger
      Panzer.logger
    end

    def fill
      return if exiting?
      @mutex.synchronize do
        logger.debug { "filling pool (#{@pool.size} -> #{count})" }
        until @pool.size >= count
          @pool << worker.spawn.pid
        end
      end
    end

    def terminate
      return if exiting?
      @exiting = true

      logger.debug { "stopping workers" }
      timer = Timeout.new(timeout)

      @pool.each do |pid|
        terminate_worker(pid)
      end

      until @pool.empty? || timer.elapsed?
        collect(timer)
      end

      @pool.each do |pid|
        kill_worker(pid)
      end
    end

    private def terminate_worker(pid)
      begin
        logger.debug { "terminating worker #{pid}" }
        Process.kill(Signal::TERM, pid)
      rescue ex : Errno
        raise ex unless ex.errno == Errno::ESRCH
      end
    end

    private def kill_worker(pid)
      begin
        logger.debug { "killing worker #{pid}" }
        Process.kill(Signal::INT, pid)
      rescue ex : Errno
        raise ex unless ex.errno == Errno::ESRCH
      end
    end

    def collect(timer = nil)
      while ret = Process.waitpid(-1)
        pid, exit_code = ret

        @mutex.synchronize do
          @pool.delete(pid)
        end

        unless exiting?
          logger.error { "worker #{pid} terminated (exit code: #{exit_code})" }
        end
      end
    end

    def exiting?
      @exiting
    end
  end
end
