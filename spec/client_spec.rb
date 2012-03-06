$: << File.dirname(__FILE__) + "/.."

require 'spec/spec_helper'
require 'harper/client'

describe HarperClient do

  subject { HarperClient.new }

  describe '#start' do
    it "should start on port 4568" do
      Kernel.should_receive(:system).with("harper --port 4568 --bg")
      subject.start
    end

    it "should be started after calling start" do
      Kernel.stub!(:system)
      subject.start
      subject.should be_started
    end
  end

  describe '#stop' do
    before(:each) do
      Kernel.stub!(:system)
      subject.start
    end

    it "should put a quit command to the control interface" do
      HarperClient.should_receive(:put).with("/h/control", :body => "{\"command\":\"quit\"}")
      subject.stop
    end

    it "should not be started" do
      HarperClient.stub!(:put)
      subject.stop
      subject.should_not be_started
    end
  end

  describe '#mock' do
    describe 'using a hash' do
      let(:mock_def) { {:sample => "hash" } }
      
      it "should post to the mocks interface" do
        HarperClient.should_receive(:post).with("/h/mocks", :body => mock_def.to_json)
        subject.mock(mock_def)
      end
    end

    describe 'using a string' do
      let(:mock_def) { "sample" }

      it "should post to the mocks interface" do
        HarperClient.should_receive(:post).with("/h/mocks", :body => mock_def)
        subject.mock(mock_def)
      end
    end
  end

end
