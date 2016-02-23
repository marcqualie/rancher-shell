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
        instance.setup_websocket!
        instance.listen!
      end

      attr_reader :api, :websocket

      def initialize
        @config_file_path = "#{ENV['HOME']}/.rancher-shell.yml"
        @config = YAML.load_file(@config_file_path)
        @projects = @config['projects']
        @project = @config['projects'].find { |project| project['id'] === @config['project'] } || @config['projects'].first
        logger.info "Environment = #{@project['name']}"
        logger.debug "  #{@project}"
        exit_with_error "API Host Required" unless @project['api'] && @project['api']['host']
        exit_with_error "API Key Required" unless @project['api'] && @project['api']['key']
        exit_with_error "API Secret Required" unless @project['api'] && @project['api']['secret']
      end

      def listen!
        $stdin.each_line do |command|
          if command.strip === 'exit'
            logger.info "connection closed"
            Kernel.exit true
          end
          @websocket.send Base64.encode64 command
        end
      end

      def setup_api!
        @api = Rancher::Shell::Api.new(
          host: @project['api']['host'],
          user: @project['api']['key'],
          pass: @project['api']['secret'],
        )
      end

      def setup_websocket!
        @response = @api.post(
          "containers/#{@config['container']}?action=execute",
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
          @buffer ||= ''
          @buffer << chunk if chunk
          if chunk.ord === 32
            emit :message, @buffer
            @buffer = ''
          end
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
