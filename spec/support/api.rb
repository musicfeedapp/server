module ApiHelper
  def response
    last_response rescue @response
  end

  def json_response &block
    block.call JSON.parse(response.body)
  end

  def client_get(path, options = {})
    get "/#{path}", options
  end

  def client_post(path, options = {})
    post "/#{path}", options
  end

  def client_put(path, options = {})
    put "/#{path}", options
  end

  def client_delete(path, options = {})
    delete "/#{path}", options
  end

  def v2_client_get(path, options = {})
    get "/v2/#{path}", options
  end

  def v2_client_post(path, options = {})
    post "/v2/#{path}", options
  end

  def v2_client_put(path, options = {})
    put "/v2/#{path}", options
  end

  def v2_client_delete(path, options = {})
    delete "/v2/#{path}", options
  end

  def v3_client_get(path, options = {})
    get "/v3/#{path}", options
  end

  def v3_client_post(path, options = {})
    post "/v3/#{path}", options
  end

  def v5_client_post(path, options = {})
    post "/v5/#{path}", options
  end

  def v5_client_put(path, options = {})
    put "/v5/#{path}", options
  end

  def v3_client_put(path, options = {})
    put "/v3/#{path}", options
  end

  def v3_client_delete(path, options = {})
    delete "/v3/#{path}", options
  end

  def v4_client_get(path, options = {})
    get "/v4/#{path}", options
  end

  def v5_client_get(path, options = {})
    get "/v5/#{path}", options
  end
end

RSpec::Matchers.define :be_unauthorized do
  match do |response|
    response.status.should == 401
  end
end

RSpec::Matchers.define :be_bad_request do
  match do |response|
    response.status.should == 400
  end
end

RSpec::Matchers.define :be_error do
  match do |response|
    response.status.should == 204
  end
end

def describe_api klass, &block
  describe klass, api: true do
    define_method(:app) do
      klass
    end

    subject { app }

    let(:route_prefix) { '/api' }

    instance_eval(&block)
  end
end

def describe_admin_api klass, &block
  describe klass, api: true do
    define_method(:app) do
      klass
    end

    subject { app }

    let(:route_prefix) { '/api/admin' }

    instance_eval(&block)
  end
end

def describe_client_api klass, options = {}, &block
  describe klass, { api: true }.merge(options) do
    define_method(:app) do
      klass
    end

    subject { app }

    let(:route_prefix) { '/' }

    instance_eval(&block)
  end
end

