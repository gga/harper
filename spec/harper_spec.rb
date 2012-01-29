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

  context "controlling harper" do
    
    it "should exit, abruptly, on demand" do
      host = mock('hosting server')
      host.should_receive(:shutdown)
      Harper::App.server(host)
      put '/h/control', {:command => "quit"}.to_json
    end
  end

end
