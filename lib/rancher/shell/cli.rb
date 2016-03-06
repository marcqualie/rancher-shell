require 'rancher/shell/commands/exec'
require 'rancher/shell/config'
require 'thor'

module Rancher
  module Shell
    class CLI < Thor

      desc "exec [COMMAND]", "Execute a command within a docker container"
      option :project, required: true
      option :container, required: true
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

      desc "list-containers", "List all containers available within a project"
      option :project, required: true
      def list_containers
        Config.load
        projects = Config.get('projects')
        project = projects.find { |_| _['id'] == options[:project] }
        api = Rancher::Shell::Api.new(
          host: project['api']['host'],
          user: project['api']['key'],
          pass: project['api']['secret'],
        )
        containers = api.get('containers?state=running').json['data']
        containers.each do |container|
          print container['id'].ljust 12
          print container['state'].ljust 12
          print container['name'].ljust 40
          print container['ports'] if container['ports'] && container['ports'] != ''
          print "\n"
        end
      end
    end
  end
end
