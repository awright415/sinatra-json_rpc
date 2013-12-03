require 'sinatra/json_rpc/version'
require 'sinatra/json_rpc/errors'
require 'sinatra/json_rpc/request'
require 'sinatra/json_rpc/response'
require 'sinatra/param'
require 'sinatra/base'
require 'multi_json'
require 'JSON'

module Sinatra
  module JsonRpc
    module Helpers
      def send_error(code, data = nil)
        resp = Sinatra::JsonRpc::Response.new
        if @rpc_req
          resp.id = @rpc_req.id unless @rpc_req.id.nil?
        end
        resp.error = code
        resp.error.data = data unless data.nil?
        resp.to_json
      end

      def send_result(result)
        halt 204 if @rpc_req.id.nil? # JSON-RPC requests without an ID are notifications, requiring
        resp = Sinatra::JsonRpc::Response.new(@rpc_req.id)
        resp.result = result
        resp.to_json
      end
    end

    def self.registered(app)
      app.helpers Sinatra::JsonRpc::Helpers, Sinatra::Param

      # Create a Sinatra::JsonRpc::Request from request body
      app.before do
        raise Sinatra::JsonRpc::ParseError unless request.media_type == 'application/json'
        @rpc_req = Sinatra::JsonRpc::Request.new.from_json(request.body.read)
        @rpc_req.valid?

        if @rpc_req.params
          if @rpc_req.params.is_a?(Array)
            @params[:splat] = *@rpc_req.params
          else
            @rpc_req.params.each { |k,v| params[k.to_sym] = v }
          end
        end
      end

      # Test whether or not the conditional route matches the JSON-RPC method contained in the request
      app.set(:method) { |value| condition { @rpc_req.method == value } }

      app.not_found do
        status 400
        send_error -32601
      end

      [ Sinatra::JsonRpc::ParseError, MultiJson::LoadError ].each do |err|
        app.error err do
          status 400
          send_error -32700
        end
      end

      app.error Sinatra::JsonRpc::RequestError do
        status 400
        send_error -32600
      end

      app.error Sinatra::JsonRpc::ResponseError do
        status 500
        send_error -32603
      end

      app.error 400 do
        send_error -32602 if body.first.start_with?("Invalid parameter")
      end
    end

  end
  register JsonRpc
end