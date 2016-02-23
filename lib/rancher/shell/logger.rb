module Rancher
  module Shell
    class Logger
      def debug message
        $stdout.puts "[#{DateTime.now.strftime '%Y-%m-%d %H:%M:%S'}] DEBUG -- : #{message}"
      end

      def info message
        $stdout.puts "[#{DateTime.now.strftime '%Y-%m-%d %H:%M:%S'}]  INFO -- : #{message}"
      end

      def error message
        $stderr.puts "[#{DateTime.now.strftime '%Y-%m-%d %H:%M:%S'}] ERROR -- : #{message}"
      end

      def warn message
        $stderr.puts "[#{DateTime.now.strftime '%Y-%m-%d %H:%M:%S'}]  WARN -- : #{message}"
      end

      def out message
        $stdout.puts "[#{DateTime.now.strftime '%Y-%m-%d %H:%M:%S'}]       -- : #{message}"
      end
    end
  end
end
