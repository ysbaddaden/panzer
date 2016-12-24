require "http"
require "../src/monitor"

class MyWorker
  include Panzer::Worker

  def initialize(port = 8080)
    @server = HTTP::Server.new(port) do |context|
      context.response.content_type = "text/plain"
      context.response << "Hello World 2!\n"
    end
    @server.bind
  end

  def run
    logger.progname = "http"
    @server.listen
  end
end

Panzer.logger.progname = "panzer:monitor"
Panzer.logger.level = Logger::Severity::DEBUG

Panzer::Monitor.run(MyWorker.new, count: 4)
