require "logger"

module Panzer
  @@logger : Logger?

  def self.logger
    @@logger ||= begin
      logger = Logger.new(STDOUT)
      logger.level = Logger::Severity::INFO
      logger.progname = "panzer"
      logger
    end
  end

  def self.logger=(@@logger)
  end
end
