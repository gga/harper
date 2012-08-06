$: << File.dirname(__FILE__) + "/.."

require 'spec/spec_helper'
require 'harper'

describe Harper::App do
  include Rack::Test::Methods
  supported_verbs = ["GET", "POST", "PUT", "DELETE"]

  let(:app) { Harper::App.new }

  let(:method) { "GET" }
  let(:url) { "/service" }
  let(:status_code) { 200 }
  let(:content_type) { "text/plain" }
  let(:body) { "fake body" }
  let(:delay) { 0 }

  let(:mock_def) do
    { :method => method,
      :url => url,
      :delay => delay,
      :'content-type' => content_type,
      :body => body }.to_json
  end

  it "should allow all mocks to be deleted" do
    post '/h/mocks', mock_def

    delete '/h/mocks'
    last_response.should be_ok
    get url
    last_response.status.should == 503
  end

  describe "mock methods are case insensitive:" do
    supported_verbs.each do |http_verb|
      [lambda { |v| v.upcase },
       lambda { |v| v.downcase },
       lambda { |v| v[0..0] + v[1..-1].downcase}].each do |fn|
          cased_verb = fn.call(http_verb)
          context cased_verb do
            let(:method) { cased_verb }

            before(:each) do
              post '/h/mocks', mock_def
              @created_mock = last_response.headers['location']
            end

            after(:each) do
              delete @created_mock
            end

            it "is a valid method" do
              self.send(cased_verb.downcase.to_sym, url)
              last_response.should be_ok
            end
          end
      end
    end
  end

  supported_verbs.each do |http_verb|
    context "#{http_verb} mock" do
      let(:method) { http_verb }

      before(:each) do
        post '/h/mocks', mock_def
      end

      it "should respond with a 201 created" do
        last_response.status.should == 201
      end

      it "should point to a newly created mock resource" do
        last_response.headers['Location'].should match(%r{/h/mocks/})
      end

      context "long service urls" do
        let(:url) { "http://www.averylong.com/url/thathas/multiple/slashes/and/thelike/" }
        it "should be queryable" do
          get last_response.headers['Location']
          last_response.status.should == 200
        end
      end

      context "is a mock" do
        before(:each) do
          self.send(method.downcase.to_sym, url)
        end

        it "has a mocked status code" do
          last_response.status.should == status_code
        end
        it "has a mocked content-type" do
          last_response.headers['Content-Type'].should match(content_type)
        end
        it "has a mocked body" do
          last_response.body.should == body
        end
        it "should not support unmocked HTTP methods" do
          (supported_verbs - [method]).each do |non_method|
            self.send(non_method.downcase.to_sym, url)
            last_response.status.should == 503
          end
        end
      end

      it "should allow the mock resource to be deleted" do
        delete last_response.headers['Location']
        last_response.should be_ok
        self.send(method.downcase.to_sym, url)
        last_response.status.should == 503
      end
    end
  end

  context "delayed mocks" do

    before(:each) do
      post '/h/mocks', mock_def
      @created_mock = last_response.headers['location']
    end

    after(:each) do
      delete @created_mock
    end

    context "short delay" do
      let(:delay) { 100 }

      it "should take at least the specified delay to provide a response" do
        time { get url }.should >= delay
      end
    end
    context "long delay" do
      let(:delay) { 1000 }

      it "should take at least the specified delay to provide a response" do
        time { get url }.should >= delay
      end
    end
    context "no delay specified" do
      let(:delay) { nil }

      it "should take close to 0 delay in providing a response" do
        time { get url }.should <= 1.0
      end
    end
  end

  context "sequential mocks" do
    let(:body) { ["b1", "b2"] }

    before(:each) do
      post '/h/mocks', mock_def
      @created_mock = last_response.headers['location']
    end

    after(:each) { delete @created_mock }

    it "should cycle through the available bodies" do
      get url
      last_response.body.should == "b1"
      get url
      last_response.body.should == "b2"
    end

  end

  context "controlling harper" do

    it "should exit, abruptly, on demand" do
      host = mock('hosting server')
      host.should_receive(:shutdown)
      Harper::App.server(host)
      put '/h/control', {:command => "quit"}.to_json
    end

  end

  context "supporting multiple mocks for same request url" do
    it "should return the mock response corresponding to the request body for xml requests" do
      url = "/service-url"

      xml_string_for_request_one = <<-EOF
        <mydoc>
          <someelement attribute="nanoo">first request</someelement>
        </mydoc>
      EOF
      body_one = "response body for request one"
      mock_def_for_first_request =
        { :method => "POST",
          :url => url,
          :'content-type' => "application/xml",
          :body => body_one,
          :request_body => xml_string_for_request_one
        }.to_json

      post '/h/mocks', mock_def_for_first_request

      xml_string_for_request_two = <<-EOF
        <mydoc>
          <someelement attribute="nanoo">Other request</someelement>
        </mydoc>
      EOF
      body_two = "response body for request two"
      mock_def_for_second_request =
      { :method => "POST",
        :url => url,
        :'content-type' => "application/xml",
        :body => body_two,
        :request_body => xml_string_for_request_two
      }.to_json

      post '/h/mocks', mock_def_for_second_request

      post url, xml_string_for_request_one
      last_response.body.should == body_one

      post url, xml_string_for_request_two
      last_response.body.should == body_two
    end

    it "should return the mock response corresponding to the request body for json requests" do
      url = "/service-url"

      request_json_one = {:param => "param 1"}.to_json
      body_one = "response body for request one"
      mock_def_for_first_request =
        { :method => "POST",
          :url => url,
          :'content-type' => "application/json",
          :body => body_one,
          :request_body => request_json_one
        }.to_json

      post '/h/mocks', mock_def_for_first_request

      request_json_two = {:param => "param 2"}.to_json
      body_two = "response body for request two"
      mock_def_for_second_request =
        { :method => "POST",
          :url => url,
          :'content-type' => "application/json",
          :body => body_two,
          :request_body => request_json_two
        }.to_json

      post '/h/mocks', mock_def_for_second_request

      post url, request_json_one
      last_response.body.should == body_one

      post url, request_json_two
      last_response.body.should == body_two
    end

    it "should return the correct response for mocks registered without any request body" do
      url = "/service-url"

      xml_string_for_request_one = <<-EOF
        <mydoc>
          <someelement attribute="nanoo">first request</someelement>
        </mydoc>
      EOF

      body_one = "response body for request one"
      mock_def_for_first_request =
        { :method => "POST",
          :url => url,
          :'content-type' => "application/xml",
          :body => body_one,
          :request_body => xml_string_for_request_one
        }.to_json

      post '/h/mocks', mock_def_for_first_request

      body_two = "response body for request two"
      mock_def_for_second_request_without_request_body =
        { :method => "POST",
          :url => url,
          :'content-type' => "application/xml",
          :body => body_two
        }.to_json

      post '/h/mocks', mock_def_for_second_request_without_request_body

      post url, xml_string_for_request_one
      last_response.body.should == body_one

      post url
      last_response.body.should == body_two
    end
  end

  context "support for cookies" do

    it "should send back cookies registered in the mock" do
      mock =
        {:method => "POST",
         :url => "url",
         :'content-type' => "application/xml",
         :body => "body",
         :cookies => {"UserID" => "JohnDoe","sampleCookie" => "cookieValue"}
        }.to_json

      post '/h/mocks', mock

      post "url"

      last_response.headers["Set-Cookie"].should == "UserID=JohnDoe\nsampleCookie=cookieValue"
    end
  end
end
