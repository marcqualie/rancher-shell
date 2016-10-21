require 'rancher/shell/logger'

module Rancher
  module Shell
    module LoggerHelper
      def logger
        @logger ||= Logger.new(STDOUT)
      end

      def exit_with_error(message)
        logger.error(message)
        Kernel.exit(false)
      end
    end
  end
end
