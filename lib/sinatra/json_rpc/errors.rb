module Sinatra
  module JsonRpc
    class RequestError < StandardError
    end

    class ResponseError < RuntimeError
    end

    class TypeError < TypeError
    end

    class InvalidParams < ArgumentError
    end

    class ParseError < RuntimeError
    end
  end
end