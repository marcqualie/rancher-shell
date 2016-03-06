require 'rancher/shell/commands/exec'
require 'rancher/shell/config'
require 'rancher/shell/version'
require 'thor'

module Rancher
  module Shell
    class CLI < Thor
      map %w[-v --version] => :version
      desc 'version', 'display gem version'
      def version
        puts "Rancher::Shell #{Rancher::Shell::VERSION}"
      end

      desc "exec [COMMAND]", "Execute a command within a docker container"
      option :project, aliases: '-p'
      option :container, aliases: '-c'
      option :stack, aliases: '-s'
      def exec command = nil
        Config.load(
          'project' => options[:project],
          'container' => options[:container],
          'stack' => options[:stack],
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
          print project['api']['host'].ljust 32
          print project['stacks'].keys.join(', ') unless project['stacks'].nil?
          print "\n"
        end
      end

      desc "list-containers", "List all containers available within a project"
      option :project, aliases: '-p', required: true
      def list_containers
        Config.load
        projects = Config.get('projects')
        project = projects[options[:project]]
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
          print container['imageUuid'][7..-1].ljust 48
          print container['ports'] if container['ports'] && container['ports'] != ''
          print "\n"
        end
      end
    end
  end
end
