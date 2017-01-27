require 'rancher/shell/logger'

module Rancher
  module Shell
    module LoggerHelper
      DEFAULT_LOG_FILE = "/tmp/rancher-shell.log"

      def logger
        @log_file = ENV['RANCHER_SHELL_LOG_FILE'] && File.exist?(ENV['RANCHER_SHELL_LOG_FILE']) ? ENV['RANCHER_SHELL_LOG_FILE'] : DEFAULT_LOG_FILE
        @logger ||= Logger.new(@log_file)
      end

      def exit_with_error(message)
        logger.error(message)
        Kernel.exit(false)
      end
    end
  end
end
