require 'active_model'
require 'active_model/validations'
require 'active_model/serialization'

module Sinatra
  module JsonRpc
    class Response
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON

      ERR_CODES = {
        -32700 => 'Parse error',
        -32600 => 'Invalid request',
        -32601 => 'Method not found',
        -32602 => 'Invalid params',
        -32603 => 'Internal error'
      }

      Error = Struct.new(:code, :message, :data)

      attr_accessor :jsonrpc, :id, :result

      validates :result, presence: true, unless: "@error.present?", strict: Sinatra::JsonRpc::ResponseError
      validates :error, presence: true, unless: "@result.present?", strict: Sinatra::JsonRpc::ResponseError
      validates :result, absence: true, if: "@error.present?", strict: Sinatra::JsonRpc::ResponseError
      validates :id, presence: true, if: "@result.present?", strict: Sinatra::JsonRpc::ResponseError
      validate :error_must_have_code_and_msg

      def initialize(id = nil)
        @jsonrpc, @id = "2.0", id
      end

      def error
        @error ||= Error.new
      end

      def error= (code)
        raise Sinatra::JsonRpc::ResponseError unless ERR_CODES.has_key? code
        error.code = code
        error.message = ERR_CODES[code]
      end

      def to_json
        if valid?
          data = { jsonrpc: @jsonrpc, result: @result, error: @error, id: @id }
          data.delete_if { |_,v| v.blank? }
          MultiJson.dump(data)
        end
      end

      private

      def error_must_have_code_and_msg
        if @error.present?
          raise Sinatra::JsonRpc::ResponseError unless @error.code.present? && @error.message.present?
        end
      end

    end
  end
end
