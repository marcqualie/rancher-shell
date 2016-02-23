require 'rancher/shell/api'
require 'rancher/shell/websocket_client'

module Rancher
  module Shell
    class CLI
      def self.start
        instance = self.new
        instance.setup_api
        instance.setup_websocket
        $stdin.each_line do |command|
          if command.strip === 'exit'
            puts ".. goodbye!"
            Kernel.exit true
          end
          instance.websocket.send Base64.encode64 command
        end
      end

      attr_reader :api, :websocket

      def setup_api
        @api = Rancher::Shell::Api.new(
          user: ENV['RANCHER_API_KEY'],
          pass: ENV['RANCHER_API_SECRET'],
          host: ENV['RANCHER_API_HOST'],
          project: ENV['RANCHER_API_PROJECT'],
          container: ENV['RANCHER_API_CONTAINER'],
        )
      end

      def setup_websocket
        @response = @api.post(
          "containers/#{ENV['RANCHER_API_CONTAINER']}?action=execute",
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
        $stdout.puts "connecting to #{@response.json['url']} ..."
        @websocket = Rancher::Shell::WebsocketClient.new websocket_url, headers: { 'Authorization' => "Bearer #{@response.json['token']}"}
        @websocket.on :open do |event|
          $stdout.puts ".. connected!"
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
          puts "SOCKET ERROR: #{event.data}"
        end
        @websocket.on :close do |event|
          puts "CLOSED SOCKET"
          puts event
          @websocket = nil
        end
      end
    end
  end
end
