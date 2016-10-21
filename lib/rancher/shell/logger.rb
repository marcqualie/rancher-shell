require "logger"

module Rancher
  module Shell
    class Logger < ::Logger
      def initialize(*args)
        super
        @formatter = Formatter.new
        # TODO: Use whitelist here for better security
        @level = ::Logger.const_get(ENV['LOG_LEVEL'].upcase) rescue ::Logger::INFO
      end

      class Formatter < ::Logger::Formatter
        # Default: "%s, [%s#%d] %5s -- %s: %s\n"
        Format = "%s, [%s#%d] %5s -- %s: [RANCHER::SHELL] %s\n"

        def call(severity, time, progname, msg)
          Format % [severity[0..0], format_datetime(time), $$, severity, progname, msg2str(msg)]
        end
      end
    end
  end
end
