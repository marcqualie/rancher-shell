#!/usr/bin/env ruby
$:.unshift 'lib'
require 'eventmachine'
require 'rancher/api'
require 'rancher/websocket_client'

EventMachine.run do

  # Initialize API
  rancher_api = Rancher::Api.new(
    user: ENV['RANCHER_API_KEY'],
    pass: ENV['RANCHER_API_SECRET'],
    host: ENV['RANCHER_API_HOST'],
    project: ENV['RANCHER_API_PROJECT'],
    container: ENV['RANCHER_API_CONTAINER'],
  )

  # Get WebSocket Access Token
  @response = rancher_api.post(
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
  # puts response.json

  # Connect to websocket
  # websocket_url = @response.json['url']
  websocket_url = "#{@response.json['url']}?token=#{@response.json['token']}"
  # puts "connecting to #{websocket_url}"
  @websocket = Rancher::WebsocketClient.new websocket_url, headers: { 'Authorization' => "Bearer #{@response.json['token']}"}
  @websocket.on :open do |event|
    # prompt
  end
  @buffer = ''
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
    puts event.to_yaml
    # p [:close, event.code, event.reason]
    # @websocket = nil
  end

  def prompt
    # $stdout.print "[rancher:#{@websocket && @websocket.handshaked ? 'open' : 'closed'}]> "
  end

  def send_command command
    # prompt
  end

  # Start listening for commands
  # send_command 'hostname'
  $stdin.each_line do |command|
    # Kernel.exit true if command.strip === 'quit'
    @websocket.send Base64.encode64 command
  end
end