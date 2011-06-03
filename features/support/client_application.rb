require 'httparty'
require 'json'

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
    @response = self.class.get options[:from]
  end

  def post(options)
    @response = self.class.post options[:to]
  end

  def delete(options)
    @response = self.class.delete options[:at]
  end

  def put(options)
    @response = self.class.put options[:to]
  end
end
