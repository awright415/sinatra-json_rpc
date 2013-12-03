ENV['RACK_ENV'] = 'test'
require 'sinatra/json_rpc'
require 'sinatra/param'
require 'rspec'
require 'rack/test'

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe Sinatra::JsonRpc do

  before :all do
    @app = Sinatra.new { register Sinatra::JsonRpc }
  end

  describe 'before filter' do
    before { @args = { :method => 'POST', :input => nil, 'CONTENT_TYPE' => 'application/json' } }

    let(:app) do
      Sinatra.new(@app) do
        post '/', :method => 'foo' do
          @rpc_req.to_json
        end

        post '/', :method => 'bar' do
          a, b, c = *params[:splat]
          "#{a}, #{b}, #{c}"
        end

        post '/', :method => 'baz' do
          "#{params[:foo]}, #{params[:bar]}, #{params[:baz]}"
        end
      end
    end

    it "parses valid JSON" do
      @args[:input] = JSON.dump({:jsonrpc => '2.0', :method => 'foo'})
      expect { request '/', @args }.to_not raise_exception
    end

    it "returns a parse error for invalid JSON" do
      @args[:input] = "''"
      request '/', @args

      expect(last_response.status).to be(400)
      expect(last_response.body).to include('Parse error')
    end

    it "adds @rpc_req.params to params[:splat] if array" do
      @args[:input] = JSON.dump({:jsonrpc => '2.0', :method => 'bar', :params => %w(foo bar baz) })
      request '/', @args

      expect(last_response.body.to_s).to eq("foo, bar, baz")
    end

    it "adds each @rpc_req.params[:key] to params[:key] if hash" do
      @args[:input] = JSON.dump({:jsonrpc => '2.0', :method => 'baz', :params => {foo: 'foo', bar: 'bar', baz: 'baz'} })
      request '/', @args

      expect(last_response.body.to_s).to eq("foo, bar, baz")
    end
  end

  describe 'send_error' do
    before(:each) { @args = { :method => 'POST', 'CONTENT_TYPE' => 'application/json' } }

    let(:app) do
      Sinatra.new(@app) do
        post '/', :method => 'foo' do
          send_error -32700
        end

        post '/', :method => 'bar' do
          send_error -32700, 'baz'
        end
      end
    end

    it "returns a valid JSON-RPC error response with id" do
      mock = Sinatra::JsonRpc::Response.new(12345)
      mock.error = -32700

      @args[:input] = JSON.dump({jsonrpc: '2.0', :method => 'foo', :id => 12345 })
      request '/', @args

      expect(last_response.body.to_s).to eq(mock.to_json)
    end

    it "returns a valid JSON-RPC error response without id" do
      mock = Sinatra::JsonRpc::Response.new
      mock.error = -32600
      mock.id = nil

      @args[:input] = JSON.dump({})
      request '/', @args

      expect(last_response.body.to_s).to eq(mock.to_json)
    end

    it "takes an optional data message and includes it in the response" do
      mock = Sinatra::JsonRpc::Response.new
      mock.error = -32700
      mock.error.data = 'baz'

      @args[:input] = JSON.dump({ jsonrpc: '2.0', :method => 'bar' })
      request '/', @args

      expect(last_response.body.to_s).to eq(mock.to_json)
    end
  end

  describe 'send_result' do
    before(:each) { @args = { method: 'POST', 'CONTENT_TYPE' => 'application/json' } }

    let(:app) do
      Sinatra.new(@app) do
        post '/' do
          send_result 'Success'
        end
      end
    end

    it 'returns a valid JSON-RPC result' do
      mock = Sinatra::JsonRpc::Response.new(12345)
      mock.result = 'Success'

      @args[:input] = JSON.dump({ jsonrpc: '2.0', method: 'foo', id: 12345 })
      request '/', @args

      expect(last_response.body.to_s).to eq(mock.to_json)
    end

    it 'does not send a response body for JSON-RPC notifications' do
      @args[:input] = JSON.dump({ jsonrpc: '2.0', method: 'foo' })
      request '/', @args

      expect(last_response.status).to be(204)
      expect(last_response.body).to be_empty
    end
  end

  context 'with a valid JSON-RPC request' do
    let(:app) do
      Sinatra.new(@app) do
        post '/', :method => 'foo' do
          send_result 'bar'
        end
      end
    end

    describe "POST /" do
      it "matches the JSON-RPC method to a conditional route" do
        mock = { jsonrpc: '2.0', result: 'bar', id: 12345 }.to_json
        request '/', :method => 'POST', :input => JSON.dump({:jsonrpc => '2.0', :method => 'foo', :id => 12345}), 'CONTENT_TYPE' => 'application/json'

        expect(last_response.status).to be(200)
        expect(last_response.body).to eq(mock)
      end

      it "returns method not found if it can't match JSON-RPC method" do
        mock = { jsonrpc: '2.0', error: { code: -32601, message: 'Method not found', data: nil }, id: 12345 }.to_json

        args = { :method => 'POST', :input => JSON.dump({ :jsonrpc => '2.0', :method => 'baz', :id => 12345}), 'CONTENT_TYPE' => 'application/json' }
        request '/', args

        expect(last_response.status).to be(400)
        expect(last_response.body).to eq(mock)
      end

    end
  end

  context 'with an invalid JSON-RPC request' do
    let(:app) do
      Sinatra.new do
        register Sinatra::JsonRpc

        post '/', :method => 'foo' do
          'bar'
        end

        post '/', :method => 'bar' do
          param :baz,   String, required: true
        end
      end
    end

    describe "POST /" do
      it "rejects content types other than JSON" do
        mock = { jsonrpc: "2.0", error: { code: -32700, message: 'Parse error', data: nil } }.to_json
        request '/', :method => 'POST', 'CONTENT_TYPE' => 'application/xml'

        expect(last_response.status).to eq(400)
        expect(last_response.body.to_s).to eq(mock)
      end

      it "returns an error if required parameters are missing" do
        mock = { jsonrpc: "2.0", error: { code: -32602, message: 'Invalid params', data: nil } }.to_json
        req_body = { jsonrpc: "2.0", method: 'bar' }.to_json
        request '/', :method => 'POST', :input => req_body, 'CONTENT_TYPE' => 'application/json'

        expect(last_response.status).to eq(400)
        expect(last_response.body.to_s).to eq(mock)
      end

    end
  end
end
