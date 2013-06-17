require 'json'
require 'httparty'

class DestroyedProducer
end

class Producer
  def destroy
    return DestroyedProducer.new
  end
end

class Consumer
end

class CWR
  include HTTParty

  attr_accessor :access_token, :email, :password, :producer
  alias_method :username, :email

  def initialize(captian_webhooks_base_uri='http://0.0.0.0:3000')
    self.class.base_uri captian_webhooks_base_uri
  end

  def username=(other)
    @email = other
  end

  def create_producer(producer_name)
    return Producer.new
  end

  def list_producers
    return [Producer.new]
  end

  def create_consumer
  end

  def webhook
    require_access_token
    self.class.post
  end

  protected

  def register_producer
    raise "@producer required to register" unless @producer
  end

  def require_access_token
    create_new_access_token_if_able unless access_token
    raise "access_token required for webhook" unless access_token
  end

  def create_new_access_token_if_able
    @username and @password and new_access_token
  end

  def new_access_token
    access_token = { email: @email,
      password: @password }
    body = { access_token: access_token }
    headers = { 'Content-Type' => 'application/json' }
    resp = self.class.post("/access_tokens",
                           body: body.to_json,
                           headers: headers)
    @access_token = resp["access_token"]["id"]
  end

  def securely_post(post_body, options)
    require_access_token
  end
end
