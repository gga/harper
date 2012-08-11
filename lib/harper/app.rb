require 'base64'
require 'sinatra/base'
require 'logger'
require 'json'

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
      def cookies(mock)
        mock["cookies"].each_pair do |key, value|
          response.set_cookie(key, value)
        end
      end

      def logger
        LOGGER
      end

      def mock_id(url)
        [url].pack('m').tr("+/=", "-_.").gsub("\n", '')
      end

      def retrieve_mock(mock_id, http_method, request_body, request_cookies)
        if @@mocks[mock_id]
          return @@mocks[mock_id].first if @@mocks[mock_id].length == 1
          mocks_matching_http_method = filter_by_http_method(http_method, mock_id)
          mocks_filtered_by_request_body = filter_by_request_body(mocks_matching_http_method, request_body)
          filtered_mocks = mocks_filtered_by_request_body || mocks_matching_http_method
          mock_matching_cookies = filter_by_cookies(filtered_mocks, request_cookies)
          if mock_matching_cookies then
            mock_matching_cookies
          else
            if mocks_matching_request_body_exist?(mocks_filtered_by_request_body)
              mock_matching_request_body_but_not_cookie(mocks_filtered_by_request_body)
            else
              mock_matching_http_method_but_not_request_body(mocks_matching_http_method)
            end
          end
        end
      end
    end

    def mocks_matching_request_body_exist?(mocks_filtered_by_request_body)
      mocks_filtered_by_request_body && !mocks_filtered_by_request_body.empty?
    end

    def mock_matching_http_method_but_not_request_body(mocks)
      mocks.detect { |m| m["request_body"].nil? }
    end

    def mock_matching_request_body_but_not_cookie(mocks)
      mocks.detect { |m| m["request_cookies"].nil? }
    end

    def filter_by_cookies(mocks, request_cookies)
      mocks.detect do |mock|
        mock["request_cookies"] && request_cookies_contain_all_cookies_registered_in_mock?(mock, request_cookies)
      end if request_cookies
    end

    def request_cookies_contain_all_cookies_registered_in_mock?(mock, request_cookies)
      mock["request_cookies"].each_pair do |key, value|
        if request_cookies[key] != value
          return false
        end
      end
      true
    end

    def filter_by_request_body(mocks_for_requested_http_method, request_body)
      mocks_for_requested_http_method.select { |m| m["request_body"] && request_body =~ /#{m["request_body"]}/ }  unless request_body.empty?
    end

    def filter_by_http_method(http_method, mock_id)
      @@mocks[mock_id].select { |m| m['method'] == http_method }
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

        request_body = request.body.read if request.body
        mock = retrieve_mock(mock_id, request.request_method, request_body, request.cookies)

        if mock
          cookies(mock) if mock["cookies"]
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
