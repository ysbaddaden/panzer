# FIXME: use a monotonic clock
struct Timeout
  class Error < Exception
  end

  def self.new(seconds : Int, message = nil)
    new(seconds.seconds, message)
  end

  def initialize(@span : Time::Span, @message : String? = nil)
    @start = Time.now
  end

  def elapsed?
    (Time.now - @start) > @span
  end

  def verify!
    raise Error.new(@message || "Reached #{@span} timeout") if elapsed?
  end
end
