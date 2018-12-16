# Sinatra::JsonRpc

Basic implementation of [JSON-RPC 2.0](http://www.jsonrpc.org/specification) for Sinatra, making quick-and-dirty APIs less dirty but no less quick.

### TO-DO:

- Improve/DRY up tests
- Create a sample app
- Add support for batch requests, per JSON-RPC spec
- Improve handling of array-based params
- Improve support for error messages, especially around the validation errors

## Installation

Add this line to your application's Gemfile:

    gem 'sinatra-json_rpc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install sinatra-json_rpc

## Usage

### Getting Started
1. Start by creating a Sinatra app.
2. Add the extension with either `require 'sinatra/json_rpc'` (classic Sinatra) or `register Sinatra::JsonRpc` (modular Sinatra)
3. Create your first method handler by adding `:method => 'foo'` to a `post '/'` route handler.

### Concepts

#### Methods

Your Sinatra app matches the methods in the JSON-RPC request against a special `:method` conditional. If your API supplies a method called 'foo', a basic handler would look like this:

```ruby
post '/', :method => 'foo' do
    send_result 'Insert return value of your choosing here'
end
```

#### Responses via `send_result` and `send_error`

To conveniently create proper JSON-RPC responses, two special handlers are defined called `send_result` and `send_error`

You supply just one argument to `send_result`, and that's the return value you want to send the client (shown above)

Sending an error requires an error code (as defined in the [JSON-RPC 2.0 spec](http://www.jsonrpc.org/specification#error_object)) and takes an optional message parameter. For example:

```ruby
send_error -32603, 'Connection with external API failed'
```

But you probably won't need to call `send_errors` directly, because of the built-in error handling.

#### Error Handling

Sinatra::JsonRpc handles a lot of the basic JSON-RPC errors for you as it goes about its business, including:

- -37200 errors for unparseable JSON in the request
- -32600 errors for requests that are valid JSON but don't follow the JSON-RPC 2.0 spec, and
- -32601 errors for requests that name an undefined method

The extension also provides handlers for standard JSON-RPC error codes, so you can simply raise an exception and let the extension create and send the error.

For example, if you want to validate required params _manually_, you can use `raise Sinatra::JsonRpc::InvalidParams` and the error response is handled automatically.

There's a similar handler for server-side errors you might encounter named `Sinatra::JsonRpc::ResponseError`

#### Required Parameters

The extension uses Sinatra::Params to provide a convenient interface for required parameters and types. Using the `foo` method from the first example, if it required a string called `bar` and an integer called `baz`, your handler would look like:

```ruby
post '/', :method => 'foo' do
    param :bar,     String, required: true
    param :baz,     Integer, required: true

    send_result "You successfully called foo with bar: #{params[:bar]} and baz: #{params[:baz]}"
end
```

You'll notice that the parameters passed in via the JSON-RPC request have been added to Sinatra's standard `params` hash. If the request params are sent as an object, values are available in `params` via their hash keys. If the params are sent as an array, the array is stored in `params[:splat]`. Array example:

```ruby
# With [1, 2] passed in as request parameters

post '/' :method => 'foo' do
    bar, baz, oops = *params[:splat]
    raise Sinatra::JsonRpc::InvalidParams if [bar, baz, oops].any? { |param| param.nil? }

    send_result 'Success'
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
