require 'rancher/shell/logger'

module Rancher
  module Shell
    module LoggerHelper
      LOG_FILE = ENV['RANCHER_SHELL_LOG_FILE'] || "/tmp/rancher-shell.log"

      def logger
        @logger ||= Logger.new(LOG_FILE)
      end

      def exit_with_error(message)
        logger.error(message)
        Kernel.exit(false)
      end
    end
  end
end
