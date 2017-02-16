require 'rancher/shell/commands/exec'
require 'rancher/shell/config'
require 'rancher/shell/version'
require 'thor'

module Rancher
  module Shell
    class CLI < Thor
      include LoggerHelper

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
          'environment' => options[:environment],
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
        projects.each do |key, project|
          print key.ljust 24
          print project['name'].ljust 32
          print project['api']['host'].ljust 32
          print project['stacks'].keys.join(', ') unless project['stacks'].nil?
          print "\n"
        end
      end

      desc "list-containers", "List all containers available within a project"
      option :project, aliases: '-p'
      def list_containers
        Config.load(
          'project' => options[:project],
        )
        project = Config.get('project')
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

      desc "logs", "Display logs"
      option :tail, aliases: '-t'
      option :lines, aliases: '-n'
      def logs
        filename = logger.instance_variable_get(:'@logdev').filename
        tail_command = "tail#{options[:tail] ? " -f -n#{options[:lines] || 0}" : " -n#{options[:lines] || 10}"} #{filename}"
        puts "==> displaying logs from #{filename} <=="
        puts "    #{tail_command}"
        begin
          if options[:tail]
            f = IO.popen(tail_command.split(' '))
            loop do
              Kernel.select([f])
              while line = f.gets do
                puts line
              end
            end
          else
            puts `#{tail_command}`
          end
        rescue Exception => e
          puts "    #{e.message}"
          puts "==> end of log output <=="
        end
      end
    end
  end
end
