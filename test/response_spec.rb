require 'sinatra/json_rpc'
require 'rspec'

describe 'Sinatra::JsonRpc::Response' do
  before(:each) { @resp = Sinatra::JsonRpc::Response.new(12345) }

  describe '#initialize' do
    it 'creates @id using its optional id parameter' do
      expect(@resp.instance_variable_get("@id")).to eq(12345)
    end

    it 'creates a @jsonrpc variable set to "2.0"' do
      expect(@resp.instance_variable_get("@jsonrpc")).to eq("2.0")
    end
  end

  describe '.valid?' do
    it 'requires @result if @error is not present' do
      expect { @resp.valid? }.to raise_error(Sinatra::JsonRpc::ResponseError)

      @resp.result = 'foo'
      expect { @resp.valid? }.not_to raise_error
    end

    it 'requires @error if @result is not present' do
      expect { @resp.valid? }.to raise_error(Sinatra::JsonRpc::ResponseError)

      @resp.error = -32700
      expect { @resp.valid? }.not_to raise_error
    end

    it 'does not allow @result and @error to both be set' do
      @resp.result, @resp.error = 'foo', -32700
      expect { @resp.valid? }.to raise_error(Sinatra::JsonRpc::ResponseError)
    end

    it 'requires @id to be set if @result is set' do
      @resp.id, @resp.result = nil, 'foo'
      expect { @resp.valid? }.to raise_error(Sinatra::JsonRpc::ResponseError)
    end

    it 'allows @id to be nil if @error is set' do
      @resp.id, @resp.error = nil, -32700
      expect(@resp.valid?).to be_true
    end
  end

  describe "@error" do
    it 'accepts code, message, and data attributes' do
      @resp.error.code = -32700
      @resp.error.message = 'Foo'
      @resp.error.data = 'Bar'

      expect(@resp.valid?).to be_true
    end

    it 'does not accept any other keys' do
      expect { @resp.error.foo = 'bar'}.to raise_error
    end

    it 'requires code and message attributes if not nil' do
      @resp.error.code = -32700
      expect { @resp.valid? }.to raise_error(Sinatra::JsonRpc::ResponseError)
    end
  end

  describe ".to_json" do
    it 'serializes the response into valid JSON-RPC format' do
      @resp.error = -32700
      expect(@resp.to_json).to eq(JSON.dump({jsonrpc: "2.0", error: {code: -32700, message: 'Parse error', data: nil}, id: 12345}))
    end

    it 'excludes nil values for error' do
      @resp.result = 1
      expect(@resp.to_json).to_not eq(JSON.dump({jsonrpc: "2.0", error: nil, id: 12345}))
    end

    it 'excludes nil values for id' do
      @resp.error = -32700
      @resp.instance_variable_set("@id", nil)
      expect(@resp.to_json).to_not eq(JSON.dump({jsonrpc: "2.0", error: {code: -32700, message: 'Parse error', data: nil}, id: nil}))
    end

    it 'validates the response object' do
      @resp.result, @resp.error = 'Success', -32700
      expect { @resp.to_json }.to raise_error(Sinatra::JsonRpc::ResponseError)
    end
  end
end