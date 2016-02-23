require 'json'

module Rancher
  class ApiResponse
    def initialize http_response
      @http_response = http_response
    end

    def body
      @http_response.body
    end

    def json
      JSON.parse body
    end
  end
end
