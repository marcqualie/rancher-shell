require 'rancher/shell/api'
require 'rancher/shell/logger_helper'
require 'rancher/shell/websocket_client'
require 'yaml'

module Rancher
  module Shell
    class CLI
      include LoggerHelper

      def self.start
        instance = self.new
        instance.setup_api!
        instance.retrieve_containers!
        instance.setup_websocket!
        instance.listen!
      end

      attr_reader :api, :websocket

      def initialize
        @config_file_paths = [
          "#{ENV['HOME']}/.rancher-shell.yml",
          "#{Dir.pwd}/.rancher-shell.yml",
        ]
        @config = {}
        @config_file_paths.each do |file_path|
          if File.exists? file_path
            logger.debug "loading config from #{file_path}"
            config = YAML.load_file(file_path)
            logger.debug "  #{config}"
            @config.merge! config
          end
        end
        @projects = @config['projects']
        @project = @config['projects'].find { |project| project['id'] === @config['project'] } || @config['projects'].first
        logger.info "environment = #{@project['id']} - #{@project['name']}"
        logger.debug "  #{@project}"
        exit_with_error "API Host Required" unless @project['api'] && @project['api']['host']
        exit_with_error "API Key Required" unless @project['api'] && @project['api']['key']
        exit_with_error "API Secret Required" unless @project['api'] && @project['api']['secret']
      end

      def listen!
        begin
          system("stty raw")
          while input = STDIN.getc
            @websocket.send Base64.encode64 input
          end
        ensure
          system("stty -raw echo")
        end
      end

      def setup_api!
        @api = Rancher::Shell::Api.new(
          host: @project['api']['host'],
          user: @project['api']['key'],
          pass: @project['api']['secret'],
        )
      end

      def retrieve_containers!
        @response = @api.get(
          "containers",
        )
        @containers = @response.json['data'].map do |container|
          {
            'id' => container['id'],
            'name' => container['name'],
            'state' => container['state'],
            'ports' => container['ports'],
          }
        end
        @container = @containers.find { |container| container['name'] === @project['container'] }
        exit_with_error "could not find container: #{@project['container']}" unless @container
      end

      def setup_websocket!
        logger.info "container = #{@container['id']}"
        @response = @api.post(
          "containers/#{@container['id']}?action=execute",
          "command" => [
            "/bin/sh",
            "-c",
            "TERM=xterm-256color; export TERM; [ -x /bin/bash ] && ([ -x /usr/bin/script ] && /usr/bin/script -q -c \"/bin/bash\" /dev/null || exec /bin/bash) || exec /bin/sh",
          ],
          "attachStdin" => true,
          "attachStdout" => true,
          "tty" => false,
        )
        websocket_url = "#{@response.json['url']}?token=#{@response.json['token']}"
        logger.info "connecting to #{@response.json['url']} ..."
        @websocket = Rancher::Shell::WebsocketClient.new websocket_url, headers: { 'Authorization' => "Bearer #{@response.json['token']}"}
        @websocket.on :open do |event|
          logger.info "  connected!"
        end
        @websocket.on :chunk do |encoded_chunk|
          chunk = Base64.decode64 encoded_chunk
          emit :message, chunk
        end
        @websocket.on :message do |data|
          $stdout.print data
        end
        @websocket.on :error do |event|
          logger.error "socket error: #{event}"
          Kernel.exit true
        end
        @websocket.on :close do
          logger.error "closed connection"
          Kernel.exit true
        end
      end
    end
  end
end
