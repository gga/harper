require 'httparty'
require 'json'
require 'benchmark'

module HTTParty
  class Response
    attr_accessor :time
  end
end

class ClientApplication
  include HTTParty

  base_uri 'example.com'

  attr_reader :response

  def initialize
    @known_mocks = Hash.new { |h, k| h[k] = {} }
  end

  def known_mock(name, description = {})
    @known_mocks[name].merge!(description)
  end

  def define_mock(name)
    @response = self.class.post "/h/mocks", :body => @known_mocks[name][:body]
  end

  def remove_mock(name)
    @response = self.class.delete @known_mocks[name][:url]
  end

  def get(options)
    timed { @response = self.class.get options[:from] }
  end

  def post(options)
    timed { @response = self.class.post options[:to] }
  end

  def delete(options)
    timed { @response = self.class.delete options[:at] }
  end

  def put(options)
    timed { @response = self.class.put options[:to] }
  end

  def timed
    val = nil
    timed = time { val = yield }
    val.time = timed
  end
end
