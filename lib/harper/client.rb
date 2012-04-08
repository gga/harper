require 'httparty'
require 'json'

class HarperClient
  include HTTParty
  
  base_uri "localhost:4568"

  def initialize
    @started = false
  end

  def started?
    @started
  end

  def start
    Kernel.system("harper --port 4568 --bg")
    @started = true
  end

  def stop
    self.class.put "/h/control", :body => {:command => "quit"}.to_json
    @started = false
  rescue Exception => e
    # Ignore the error here as it's pretty common for the connection
    # to be killed out from under the app
  end

  def mock(mock)
    mock_body = case mock
                when String
                  mock
                else
                  mock.to_json
                end
    self.class.post "/h/mocks", :body => mock_body
  end
end
