require 'httparty'
require 'json'

class ClientApplication
  include HTTParty

  base_uri 'example.com'

  attr_reader :response

  def mock_body(content)
    @mock_body = content
  end

  def define_mock
    @response = self.class.post "/h/mocks", :body => @mock_body
  end

  def remove_mock(mock_url)
    @response = self.class.delete "/h/mocks#{mock_url}"
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
