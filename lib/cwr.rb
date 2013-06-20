require 'json'
require 'httparty'

class DestroyedProducer
end

class Producer
  def initialize(cwr, name)
    @cwr = cwr
    @name = name
  end
  
  def destroy
    return DestroyedProducer.new
  end

  def create_consumer(name)
    @cwr.create_consumer self, name
  end
  
  def create_webhook_for(consumers, webhook_post_uri, data = nil)
    @cwr.create_webhook(self, consumers, data)
  end
end

class Consumer
  def initialize(cwr, producer, name)
    @cwr = cwr
    @producer = producer
    @name = name
  end

  def destroy
    return DestroyedConsumer.new
  end
end

class Webhook
  def initialize(webhook_id, error=nil)
    @error = error
  end
  
  def hooked?
    !@error
  end
end

class DestroyedProducer
end

class DestroyedConsumer
end

class CWR
  include HTTParty

  attr_accessor :access_token, :email, :password, :producer
  alias_method :username, :email

  def initialize(captian_webhooks_base_uri='http://0.0.0.0:3000')
    self.class.base_uri captian_webhooks_base_uri
    @producer_stub = Producer.new(self, "stub")
    @consumer_stub = Consumer.new(self, @producer_stub, "stub")
    @webhook_stub = Webhook.new(1)
  end

  def username=(other)
    @email = other
  end

  def create_producer(name)
    return Producer.new( self, name )
  end

  def list_producers
    return [@producer_stub]
  end

  def create_consumer(producer, name)
    return Consumer.new( self, producer, name )
  end

  def list_consumers
    return [@consumer_stub]
  end

  def create_webhook(producer, consumers, data=nil)
    consumers = [consumers] if consumers.is_a? Consumer
    return @webhook_stub
  end

  def list_webhooks
    return []
  end

  def yeearr
    :jolly_roger
    "yeearr"
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

  def securely_post(url, body)
    require_access_token
    headers = { 'HTTP_AUTHORIZATION' => @access_token }
    headers['Content-Type'] = 'application/json'
    self.class.post(url,
                    body: body.to_json,
                    headers: headers)
  end
end
