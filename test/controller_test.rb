# frozen_string_literal: true
require File.dirname(__FILE__) + "/test_helper"

class CacheableControllerTest < Minitest::Test
  class MockRequest
    def get?
      true
    end

    def params
      {}
    end

    def env
      @env ||= {}
    end
  end

  class MockResponse
    def headers
      @headers ||= {}
    end
  end

  class MockController
    include Cacheable::Controller

    def cache_configured?
      true
    end

    def params
      {}
    end

    def request
      @request ||= MockRequest.new
    end

    def response
      @response ||= MockResponse.new
    end
  end

  def setup
    @cache_store = stub.tap { |s| s.stubs(read: nil) }
    Cacheable.cache_store = @cache_store
    Cacheable.stubs(:acquire_lock).returns(true)
  end

  def test_cache_control_no_store_set_for_uncacheable_requests
    controller.expects(:cacheable_request?).returns(false)
    controller.send(:response_cache) {}
    assert_equal(controller.response.headers['Cache-Control'], 'no-cache, no-store')
  end

  def test_server_cache_hit
    controller.request.env['gzip'] = false
    @cache_store.expects(:read).returns(page_serialized)
    controller.expects(:render).with(plain: '<body>hi.</body>', status: 200)

    controller.send(:response_cache) {}
  end

  def test_client_cache_hit
    controller.request.env['HTTP_IF_NONE_MATCH'] = 'deadbeef'
    Cacheable::ResponseCacheHandler.any_instance.expects(:versioned_key_hash).returns('deadbeef').at_least_once
    controller.expects(:head).with(:not_modified)

    controller.send(:response_cache) {}
  end

  private

  def controller
    @controller ||= MockController.new
  end

  def page_serialized
    MessagePack.dump([200, "text/html", Cacheable.compress("<body>hi.</body>"), 1331765506])
  end
end
