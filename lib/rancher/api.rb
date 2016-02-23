require 'net/http'
require 'rancher'
require 'rancher/api_response'
require 'yaml'

module Rancher
  class Api

    DEFAULT_OPTIONS = {
      user: nil,
      pass: nil,
      host: 'rancher.example.com',
      project: nil,
    }

    def initialize options = {}
      @options = DEFAULT_OPTIONS.merge options
    end

    def get resource, data = nil, headers = {}
      request :get, resource, nil, headers
    end

    def post resource, data, headers = {}
      request :post, resource, data, headers
    end

    def request method_name, resource, data, headers
      uri = URI "https://#{@options[:host]}/v1/projects/#{@options[:project]}/#{resource}"
      Net::HTTP.start uri.host, uri.port, use_ssl: true do |http|
        method_class_name = "Net::HTTP::#{method_name.to_s.split('_').map(&:capitalize).join}"
        method_class = Object.const_get method_class_name
        request = method_class.new uri
        request.basic_auth @options[:user], @options[:pass]
        request.set_form_data data if method_name === :post
        ApiResponse.new http.request request
      end
    end

  end
end
