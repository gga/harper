module Harper
  class MockFilter

    def initialize(mocks)
      @mocks = mocks
    end

    def value
      @mocks.first
    end
    
    def all
      @mocks
    end

    def by_method(actual)
      MockFilter.new(@mocks.select { |m| m['method'] == actual })
    end

    def by_body(actual)
      MockFilter.new(@mocks.select { |m| !m['request_body'] || actual =~ /#{m["request_body"]}/ })
    end

    def by_cookies(actual)
      MockFilter.new(@mocks.select { |m| !m['request_cookies'] || contains_all(m['request_cookies'], actual)})
    end

    def contains_all(sub, full)
      (sub.to_a - full.to_a).empty?
    end

  end
end
