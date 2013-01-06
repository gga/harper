$: << File.dirname(__FILE__) + "/.."

require 'spec/spec_helper'
require 'harper/mock_filter'

describe Harper::MockFilter do

  subject { Harper::MockFilter.new(starting_set) }

  context "an empty set" do
    let(:starting_set) { [] }

    it('should be nil') { subject.value.should be_nil }
  end

  context "a set of one item" do
    let(:starting_set) { [:a_mock] }

    it('should be the single item') { subject.value.should be :a_mock }
  end

  context "a set of matching mocks" do
    let(:starting_set) { [{'id' => 'first'}.merge(attrs), {'id' => 'second'}.merge(attrs)] }

    context "by methods" do
      let(:attrs) { {'method' => 'matching'} }

      it 'should return the first when filtered by method' do
        subject.by_method('matching').value['id'].should == 'first'
      end
    end

    context "by bodies" do
      let(:attrs) { {'request_body' => "match"} }

      it 'should return the first when filtered by body' do
        subject.by_body('matching').value['id'].should == 'first'
      end
    end

    context "by cookies" do
      let(:attrs) { {'request_cookies' => {'c1' => 'v1'} } }

      it 'should return the first when filtered by cookies' do
        subject.by_cookies('c1' => 'v1', 'c2' => 'v2').value['id'].should == 'first'
      end
    end
  end

  context "a set of five mocks" do
    let(:put_mock) { {'method' => 'put'} }
    let(:with_body) { {'method' => 'get', 'request_body' => 'body'} }
    let(:nothing) { {'method' => 'get'} }
    let(:with_cookies) { {'method' => 'get', 'request_cookies' => {'c' => 'v'}} }
    let(:both) { {'method' => 'get', 'request_body' => 'body', 'request_cookies' => {'c' => 'v'}} }

    let(:starting_set) { [put_mock, with_body, nothing, with_cookies, both] }

    context 'filtered by method' do
      it("should find one mock with method 'put'") { subject.by_method('put').all.should have(1).mocks }
      it("should find four mocks with method 'get'") { subject.by_method('get').all.should have(4).mocks }
    end

    context 'filtered by body' do
      it("should find five mocks with body 'body'") { subject.by_body('body').all.should have(5).mocks }
      it("should find three mocks with body 'unspecified'") { subject.by_body('unspecified').all.should have(3).mocks }
    end

    context 'filtered by cookies' do
      it("should find five mocks with cookie 'c'") { subject.by_cookies('c' => 'v').all.should have(5).mocks }
      it("should find three mocks with cookie 'c' = 'other'") { subject.by_cookies('c' => 'other').all.should have(3).mocks }
    end
  end

end
