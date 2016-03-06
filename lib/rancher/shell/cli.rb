require 'rancher/shell/commands/exec'
require 'rancher/shell/config'
require 'thor'

module Rancher
  module Shell
    class CLI < Thor

      desc "exec [COMMAND]", "Execute a command within a docker container"
      option :project
      option :container
      def exec command
        Config.load(
          'project' => options[:project],
          'container' => options[:container],
          'command' => command,
        )
        instance = Rancher::Shell::Commands::Exec.new
        instance.setup_api!
        instance.retrieve_containers!
        instance.setup_websocket!
        instance.listen!
      end

      desc "list-projects", "List all projects available via configuration"
      def list_projects
        Config.load
        projects = Config.get('projects')
        projects.each do |project|
          print project['id'].ljust 24
          print project['name'].ljust 32
          print project['api']['host']
          print "\n"
        end
      end
    end
  end
end
