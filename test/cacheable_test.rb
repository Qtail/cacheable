require File.dirname(__FILE__) + "/test_helper"

class CacheableTest < MiniTest::Unit::TestCase

  class MockRequest
    def get?; true ;end
    def params; {}; end
    def env; {}; end
  end

  class MockController
    include Cacheable::Controller

    def cache_configured?; true ;end
    def params; {}; end
    def request
      MockRequest.new
    end

  end

  def setup
    @data = {:foo => 'bar', :bar => [1,['a','b'], 2, {:baz => 'buzz'}], 'qux' => {:red => ['blue', 'green'], :day => true, :night => nil, :updated_at => Time.at(1309362467).utc, :published_on => Time.at(1309320000).utc.to_date}, :format => Mime::Type.lookup('text/html')}
  end

  def test_cache_key_for_handles_nested_everything_and_removes_hash_keys_with_nil_values
    expected = %|bar,1,a,b,2,{:baz=>\"buzz\"},{:red=>[\"blue\", \"green\"], :day=>true, :night=>nil, :updated_at=>2011-06-29 15:47:47 UTC, :published_on=>Wed, 29 Jun 2011},text/html|
    assert_equal expected, Cacheable.cache_key_for(key: @data)
  end

  def test_cache_key_with_no_key_key
    expected = %|{:foo=>\"bar\", :bar=>[1, [\"a\", \"b\"], 2, {:baz=>\"buzz\"}], \"qux\"=>{:red=>[\"blue\", \"green\"], :day=>true, :night=>nil, :updated_at=>2011-06-29 15:47:47 UTC, :published_on=>Wed, 29 Jun 2011}}|
    assert_equal expected, Cacheable.cache_key_for(@data.tap {|h| h.delete(:format) })
  end

  def test_middleware_and_controller_use_the_same_cache_store
    m = MockController.new
    Cacheable::ResponseCacheHandler.any_instance.expects(:cache_store=).with(Cacheable.cache_store)
    Cacheable::ResponseCacheHandler.any_instance.expects(:run!)
    m.response_cache
  end

  def test_cache_key_with_key_and_version
    version = { :version => 42 }
    expected = %|bar,1,a,b,2,{:baz=>\"buzz\"},{:red=>[\"blue\", \"green\"], :day=>true, :night=>nil, :updated_at=>2011-06-29 15:47:47 UTC, :published_on=>Wed, 29 Jun 2011},text/html:42|
    assert_equal expected, Cacheable.cache_key_for(key: @data, version: version)
  end
end
