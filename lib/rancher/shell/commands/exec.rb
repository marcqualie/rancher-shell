require 'rancher/shell/api'
require 'rancher/shell/logger_helper'
require 'rancher/shell/websocket_client'

module Rancher
  module Shell
    module Commands
      class Exec
        include LoggerHelper

        attr_reader :api, :websocket

        def initialize
          @config = Config.get_all
          logger.debug "config = #{@config}"
          exit_with_error "Project not found: #{@config['project']}" unless @config['project']
          exit_with_error "Command not specified" unless @config['options']['command'] && @config['options']['command'] != ''
          exit_with_error "Container not specified" unless @config['options']['container'] && @config['options']['container'] != ''
          exit_with_error "API Host Required" unless @config['project']['api'] && @config['project']['api']['host']
          exit_with_error "API Key Required" unless @config['project']['api'] && @config['project']['api']['key']
          exit_with_error "API Secret Required" unless @config['project']['api'] && @config['project']['api']['secret']
        end

        def listen!
          begin
            logger.info "listening for keyboaard input"
            system("stty raw")
            while input = STDIN.getc
              @websocket.send(Base64.encode64 input)
            end
          ensure
            system("stty -raw echo")
          end
        end

        def setup_api!
          logger.info "authorizing with #{@config['project']['api']['host']}"
          @api = Rancher::Shell::Api.new(
            host: @config['project']['api']['host'],
            user: @config['project']['api']['key'],
            pass: @config['project']['api']['secret'],
            environment: @config['project']['api']['environment'],
          )
        end

        def retrieve_containers!
          @response = @api.get(
            "containers?limit=1000",
          )
          @containers = @response.json['data'].map do |container|
            {
              'id' => container['id'],
              'name' => container['name'],
              'state' => container['state'],
              'ports' => container['ports'],
              'stack' => container['labels'] && container['labels']['io.rancher.stack.name'],
            }
          end
          logger.debug "  containers #{@containers.count}"
          @containers.sort_by { |container| "#{container['stack']}/#{container['name']}" }.each do |container|
            logger.debug "  #{container['stack']} / #{container['name']}     #{container['state']}"
          end
          @container = @containers.find { |container| container['name'] === @config['options']['container'] }
          exit_with_error "could not find container: #{@config['options']['container']}" unless @container
        end

        def setup_websocket!
          logger.info "container = #{@container['id']}"
          # default_bash_command = "TERM=xterm-256color; export TERM; [ -x /bin/bash ] && ([ -x /usr/bin/script ] && /usr/bin/script -q -c \"/bin/bash\" /dev/null || exec /bin/bash) || exec /bin/sh"
          # @config['options']['command'] = default_bash_command if @config['options']['command'] === 'bash'
          bash_command = @config['options']['command']
          logger.debug "running command: #{bash_command}"
          @response = @api.post(
            "containers/#{@container['id']}?action=execute",
            "command" => [
              "/bin/sh",
              "-c",
              bash_command,
            ],
            "attachStdin" => true,
            "attachStdout" => true,
            "tty" => true,
          )
          websocket_url = "#{@response.json['url']}?token=#{@response.json['token']}"
          logger.info "connecting to #{@response.json['url']}"
          @websocket = Rancher::Shell::WebsocketClient.new websocket_url, headers: { 'Authorization' => "Bearer #{@response.json['token']}"}
          @websocket.on :open do |event|
            logger.info "connected to websocket"
          end
          @websocket.on :chunk do |chunk_encoded|
            chunk_decoded = Base64.decode64(chunk_encoded)
            chunk_codes = chunk_decoded.split('').map { |char| char.ord.to_s }
            logger.debug("output: (#{chunk_decoded.length} bytes)")
            logger.debug("  #{chunk_encoded}")
            logger.debug("  #{chunk_codes.join(' ')}")
            logger.debug("  #{chunk_decoded}")
            $stdout.print(chunk_decoded)
          end
          @websocket.on :error do |event|
            logger.error("socket error: #{event}")
            Kernel.exit(true)
          end
          @websocket.on :close do
            logger.info("server closed connection")
            Kernel.exit(true)
          end
        end
      end
    end
  end
end
