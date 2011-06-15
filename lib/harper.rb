require 'base64'
require 'sinatra/base'
require 'logger'
require 'json'

class Harper < Sinatra::Base

  Version = "0.0.2"

  @@mocks = {}

  enable :logging

  configure do
    LOGGER = Logger.new("sinatra.log")
  end

  helpers do
    def logger
      LOGGER
    end

    def mock_id(url)
      [url].pack('m').tr("+/=", "-_.").gsub("\n", '')
    end
  end

  post '/h/mocks' do
    mock = JSON(request.body.read)

    mock['url'] = mock['url'][1..-1] if mock['url'] =~ /^\//

    mock['id'] = mock_id(mock['url'])
    mock['method'].upcase!
    mock['delay'] = mock['delay'].to_f / 1000.0
    @@mocks[mock['id']] = mock

    logger.info("Created mock for endpoint: '#{mock['url']}'")
    
    headers['location'] = "/h/mocks/#{mock['id']}"
    status "201"
  end

  delete '/h/mocks' do
    @@mocks = {}
  end

  get '/h/mocks/:mock_id' do |mock_name|
    content_type :json
    status "200"
    @@mocks[mock_name].to_json
  end

  delete '/h/mocks/:mock_id' do |mock_name|
    @@mocks[mock_name] = nil

    status "200"
  end

  [:get, :post, :put, :delete].each do |method|
    self.send(method, '*') do
      mock_id = mock_id(request.path[1..-1])

      logger.debug("#{request.request_method} request for a mock: '#{request.path}'")

      mock = @@mocks[mock_id]
      if mock && request.request_method == mock['method']
        content_type mock['content-type']
        status mock['status'] || "200"
        sleep mock['delay']
        
        logger.info("Serving mocked body for endpoint: '#{mock['url']}'")

        mock['body']
      else
        status "503"
      end
    end
  end

end
