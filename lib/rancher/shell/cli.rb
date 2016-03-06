require 'rancher/shell/commands/exec'
require 'thor'

module Rancher
  module Shell
    class CLI < Thor
      desc "exec [COMMAND]", "Execute a command within a docker container"
      option :project
      option :container
      def exec command
        instance = Rancher::Shell::Commands::Exec.new(
          'project' => options[:project],
          'container' => options[:container],
          'command' => command,
        )
        instance.setup_api!
        instance.retrieve_containers!
        instance.setup_websocket!
        instance.listen!
      end
    end
  end
end
