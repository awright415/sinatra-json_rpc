require 'active_model'
require 'active_model/validations'
require 'active_model/serialization'

module Sinatra
  module JsonRpc
    class Request
      include ActiveModel::Validations
      include ActiveModel::Serializers::JSON

      REQUEST_ERROR = Sinatra::JsonRpc::RequestError

      attr_accessor :jsonrpc, :method, :params, :id

      validates :jsonrpc, :method, presence: true, strict: REQUEST_ERROR
      validates :jsonrpc, inclusion: { in: %w(2.0) }, strict: REQUEST_ERROR
      validates :id, numericality: true, strict: REQUEST_ERROR, allow_nil: true,
        unless: Proc.new { |r| r.id.is_a? String }
      validate :params_must_be_array_or_hash

      def attributes=(hash)
        hash.each do |key, value|
          raise Sinatra::JsonRpc::RequestError unless respond_to? key
          instance_variable_set("@#{key}", value)
        end
      end

      def attributes
        {
          'jsonrpc' => "2.0",
          'method' => nil,
          'params' => nil,
          'id' => nil
        }
      end

      private

      def params_must_be_array_or_hash
        if @params.present?
          raise REQUEST_ERROR unless @params.is_a?(Array) || @params.is_a?(Hash)
        end
      end

    end
  end
end