require 'base64'
require 'sinatra/base'
require 'json'

class Harper < Sinatra::Base

  Version = "0.0.1"

  @@mocks = {}

  helpers do
    def mock_id(url)
      Base64.encode64(url).chomp
    end
  end

  post '/h/mocks' do
    mock = JSON(request.body.read)

    mock['id'] = mock_id(mock['url'])
    mock['method'].upcase!
    mock['delay'] = mock['delay'].to_f / 1000.0
    @@mocks[mock['id']] = mock

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
      mock_id = mock_id(request.path)

      mock = @@mocks[mock_id]
      if mock && request.request_method == mock['method']
        content_type mock['content-type']
        status mock['status'] || "200"
        sleep mock['delay']
        mock['body']
      else
        status "503"
      end
    end
  end

end
