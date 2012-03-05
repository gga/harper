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
    system("harper --port 4568 --bg")
    @started = true
  end

  def stop
    self.class.put "/h/control", :body => {:command => "quit"}.to_json
    @started = false
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
