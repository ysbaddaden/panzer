require "./timeout"

class Process
  # Waits for process `pid`. Returns the process exit code.
  def self.wait(pid, timeout = nil)
    timer = Timeout.new(timeout) if timeout
    loop do
      if args = waitpid(pid)
        return args[1]
      else
        timer.try(&.verify!)
        Fiber.yield
      end
    end
  end

  # Tries to collect process *pid*, or any child process if *pid* is -1. Returns
  # the collected process pid if any, otherwise returns `nil`.
  def self.waitpid(pid = -1)
    case child_pid = LibC.waitpid(pid, out exit_code, LibC::WNOHANG)
    when -1
      if pid == -1 && Errno.value == Errno::ECHILD
        # no child processes
        return
      end
      raise Errno.new("waitpid")
    when 0
      return
    else
      return {child_pid, exit_code}
    end
  end

  # Returns true if process *pid* exists and is accessible (e.g. child process),
  # and isn't in a zombie state or equivalent. Returns false otherwise.
  def self.running?(pid)
    case LibC.waitpid(pid, out exit_code, LibC::WNOHANG)
    when 0
      return true
    when -1
      unless Errno.value == Errno::ECHILD
        raise Errno.new("waitpid")
      end
    end
    false
  end
end
