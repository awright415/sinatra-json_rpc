require 'rspec'

describe Sinatra::JsonRpc::Request do
  let(:req) { Sinatra::JsonRpc::Request.new.from_json(@args.to_json) }

  describe '#initialize' do
    it 'sets values for @jsonrpc, @method, @params, and @id' do
      @args = { jsonrpc: "2.0", method: "foo", params: [0, 1, 2], id: 12345 }

      expect(req.jsonrpc).to eq("2.0")
      expect(req.method).to eq("foo")
      expect(req.params).to eq([0, 1, 2])
      expect(req.id).to eq(12345)
    end

    it 'sets nil for @jsonrpc, @method, @params, and @id if not provided' do
      @args = {}

      expect(req.jsonrpc).to be_nil
      expect(req.method).to be_nil
      expect(req.params).to be_nil
      expect(req.id).to be_nil
    end

    it 'raises an exception if hash contains any other keys' do
      @args = { foo: "bar"}
      expect {req}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end
  end

  describe '.valid?' do
    before(:each) { @args = { jsonrpc: "2.0", method: "foo", params: [0, 1, 2], id: 12345 } }

    it 'requires @jsonrpc to be present' do
      @args[:jsonrpc] = nil
      expect {req.valid?}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end

    it 'requires @jsonrpc to be a string with value 2.0' do
      @args[:jsonrpc] = 1.9
      expect {req.valid?}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end

    it 'requires @method to be present' do
      @args[:method] = nil
      expect {req.valid?}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end

    it 'allows empty values for @params and @id' do
      @args[:params], @args[:id] = nil, nil
      expect(req.valid?).to be_true
    end

    it 'allows @params to be an array' do
      expect(req.valid?).to be_true
    end

    it 'allows @params to be a hash' do
      @args[:params] = {:foo => "bar"}
      expect(req.valid?).to be_true
    end

    it 'disallows any other types for @params' do
      @args[:params] = "foo"
      expect {req.valid?}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end

    it 'allows @id to be a number' do
      expect(req.valid?).to be_true
    end

    it 'allows @id to be a string' do
      @args[:id] = "foo"

      expect(req.valid?).to be_true
    end

    it 'disallows any other types for @id' do
      @args[:id] = Object.new
      expect {req.valid?}.to raise_exception(Sinatra::JsonRpc::RequestError)
    end
  end
end