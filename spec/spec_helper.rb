require 'rack/test'
require 'sinatra'
require 'rspec/mocks/standalone'

$: << File.dirname(__FILE__) + "/.."

def time
  start = Time.now
  yield
  (Time.now - start) * 1000.0
end
