# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'sinatra/json_rpc/version'

Gem::Specification.new do |spec|
  spec.name          = "sinatra-json_rpc"
  spec.version       = Sinatra::JsonRpc::VERSION
  spec.authors       = ["Adam Wright"]
  spec.email         = ["adam.j.wright@gmail.com"]
  spec.description   = %q{Implementation of JSON-RPC for Sinatra}
  spec.summary       = %q{Designed for fast creation of JSON-RPC APIs, leveraging the simplicity and power of Sinatra}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "activemodel"
  spec.add_dependency "sinatra-param"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "rspec"
end
