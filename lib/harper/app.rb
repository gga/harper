require 'base64'
require 'sinatra/base'
require 'logger'
require 'json'

require 'harper/mock_filter'

module Harper
  class App < Sinatra::Base

    @@mocks = {}
    @@server = nil

    def self.server(server)
      @@server = server
    end

    enable :logging

    configure do
      LOGGER = Logger.new("sinatra.log")
    end

    helpers do
      def cookies(mocked_cookies)
        mocked_cookies.each_pair { |k, v| response.set_cookie(k, v) } if mocked_cookies
      end

      def logger
        LOGGER
      end

      def mock_id(url)
        [url].pack('m').tr("+/=", "-_.").gsub("\n", '')
      end

      def retrieve_mock(mock_id, request)
        if @@mocks[mock_id]
          # If there is only one mock with the id, then ignore all other filters
          return @@mocks[mock_id].first if @@mocks[mock_id].length == 1

          # Mock parameters
          method = request.request_method
          body = request.body ? request.body.read : ''
          cookies = request.cookies

          mocks_for(mock_id).by_method(method).by_body(body).by_cookies(cookies).value
        end
      end

      def mocks_for(mock_id)
        MockFilter.new(@@mocks[mock_id])
      end
    end

    post '/h/mocks' do
      mock = JSON(request.body.read)

      mock['url'] = mock['url'][1..-1] if mock['url'] =~ /^\//

      mock['id'] = mock_id(mock['url'])
      mock['method'].upcase!
      mock['delay'] = mock['delay'].to_f / 1000.0
      @@mocks[mock['id']] ||= []
      @@mocks[mock['id']] << mock

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

    put '/h/control' do
      cmd = JSON(request.body.read)

      case cmd["command"]
      when "quit"
        @@server.shutdown
      end
    end

    [:get, :post, :put, :delete].each do |method|
      self.send(method, '*') do
        mock_id = mock_id(request.path[1..-1])

        logger.debug("#{request.request_method} request for a mock: '#{request.path}'")

        mock = retrieve_mock(mock_id, request)

        if mock
          cookies mock['cookies']
          content_type mock['content-type']
          status mock['status'] || "200"
          sleep mock['delay']

          logger.info("Serving mocked body for endpoint: '#{mock['url']}'")

          case mock['body']
          when Array
            next_body = mock['next'] || -1
            mock['next'] = (next_body + 1) % mock['body'].length
            mock['body'][mock['next']]
          else
            mock['body']
          end
        else
          status "503"
        end
      end
    end

  end
end
