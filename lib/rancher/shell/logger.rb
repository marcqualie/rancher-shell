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
          msg = sanitize_escape_sequences(msg)
          Format % [severity[0..0], format_datetime(time), $$, severity, progname, msg2str(msg)]
        end

        # Some escape charatcers cause weirdness within logs and STDOUT
        #   http://www.asciitable.com/
        #   https://en.wikipedia.org/wiki/ANSI_escape_code
        def sanitize_escape_sequences(msg)
          msg = msg.gsub("\r", "[CR]")
          msg = msg.gsub("\n", "[LF]")
          msg = msg.gsub(/\e\[A/, '[CUU]')
          msg = msg.gsub(/\e\[B/, '[CUD]')
          msg = msg.gsub(/\e\[2K/, '[CLEAR]')
          msg = msg.gsub(/#{3.chr}/, '[ETX]')
          msg = msg.gsub(/#{4.chr}/, '[EOT]')
          msg = msg.gsub(/#{7.chr}/, '[BELL]')
          msg = msg.gsub(/#{8.chr}/, '[BS]')
          msg = msg.gsub(/#{9.chr}/, '[TAB]')
          msg = msg.gsub(/#{24.chr}/, '[CAN]')
          msg = msg.gsub(/#{27.chr}/, '[ESC]')
          msg = msg.gsub(/#{127.chr}/, '[DEL]')
          msg
        end
      end
    end
  end
end
