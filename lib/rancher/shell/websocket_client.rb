require 'event_emitter'
require 'rancher/shell/logger_helper'
require 'websocket'

module Rancher
  module Shell
    class WebsocketClient
      include EventEmitter
      include LoggerHelper
      attr_reader :url, :handshake, :handshaked, :thread, :socket

      def initialize url, options = {}
        return if @socket
        @url = url
        uri = URI.parse url
        @socket = TCPSocket.new(uri.host, uri.port || (uri.scheme == 'wss' ? 443 : 80))
        if ['https', 'wss'].include? uri.scheme
          ctx = OpenSSL::SSL::SSLContext.new
          ctx.ssl_version = options[:ssl_version] || 'SSLv23'
          ctx.verify_mode = options[:verify_mode] || OpenSSL::SSL::VERIFY_NONE #use VERIFY_PEER for verification
          cert_store = OpenSSL::X509::Store.new
          cert_store.set_default_paths
          ctx.cert_store = cert_store
          @socket = ::OpenSSL::SSL::SSLSocket.new(@socket, ctx)
          @socket.connect
        end
        @handshake = ::WebSocket::Handshake::Client.new :url => url, :headers => options[:headers]
        @handshaked = false
        @pipe_broken = false
        frame = ::WebSocket::Frame::Incoming::Client.new
        @closed = false

        @thread = Thread.new do
          while !@closed do
            begin
              unless recv_data = @socket.getc
                sleep 0.25
                next
              end
              unless @handshaked
                @handshake << recv_data
                if @handshake.finished?
                  @handshaked = true
                  logger.debug("handshake complete")
                  emit :open
                end
              else
                frame << recv_data
                while msg = frame.next
                  emit :chunk, msg.to_s
                end
              end
            rescue => e
              puts "broken pipe error thing"
              logger.error("EMIT ERROR: #{e.to_yaml}")
              emit :error, e
            end
          end
          logger.error("THREAD IS DEAD")
        end

        @socket.write @handshake.to_s
      end

      def send(data_encoded, opt={:type => :text})
        data_decoded = Base64.decode64(data_encoded)
        if !@handshaked or @closed
          logger.warn("cannot send data because socket is closed")
          return
        end
        type = opt[:type]
        data_codes = data_decoded.split('').map { |char| char.ord.to_s }
        logger.debug("input: (#{data_encoded.length} bytes)")
        logger.debug("  #{data_encoded}")
        logger.debug("  #{data_codes.join(' ')}")
        logger.debug("  #{data_decoded}")
        frame = ::WebSocket::Frame::Outgoing::Client.new(:data => data_encoded, :type => type, :version => @handshake.version)
        begin
          @socket.write(frame.to_s)
        rescue Errno::EPIPE => e
          puts "nroken pp"
          @pipe_broken = true
          emit :close, e
        end
      end

      def close
        return if @closed
        logger.debug("client closed connection")
        if !@pipe_broken
          send nil, :type => :close
        end
        @closed = true
        @socket.close if @socket
        @socket = nil
        Thread.kill(@thread) if @thread
      end

      def open?
        @handshake.finished? and !@closed
      end
    end
  end
end
