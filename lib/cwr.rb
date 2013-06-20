require 'json'
require 'httparty'

class DestroyedProducer
end

class Producer

  def initialize(cwr, name, producer_path=nil)
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

  def initialize(captian_webhooks_base_uri='http://0.0.0.0:3000',
                 producer_path=nil)
    @PRODUCER_PATH = producer_path || "/producers"
    self.class.base_uri captian_webhooks_base_uri
    @producer_stub = Producer.new(self, "stub")
    @consumer_stub = Consumer.new(self, @producer_stub, "stub")
    @webhook_stub = Webhook.new(1)
  end

  def username=(other)
    @email = other
  end

  def create_producer(name)
    body = { "name" => name }
    resp = securely_post( @PRODUCER_PATH, body )
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
    @username ||= @email
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

  def securely_post(path, body, headers=nil)
    require_access_token
    headers ||= {}
    headers['HTTP_AUTHORIZATION'] = @access_token
    headers['Content-Type'] = 'application/json'
    begin
      resp = self.class.post(path,
                             body: body.to_json,
                             headers: headers)
      check_response resp
    rescue Exception => e
      error = e.message + "\n"
      error += "Problem with secure post to: #{path}\n"
      error += "path: #{path}\n"
      error += "body: #{body}"
      raise error
    end
    resp
  end

  def check_response(resp)
    case resp.code
    when 400
      raise "400 - Bad Request"
    when 401
      raise "401 - Unauthorized"
    when 403
      raise "403 - Forbidden"
    when 404
      raise "404 - Not found"
    when 400..499
      raise "Client error with code #{resp.code}"
    when 500..599
      raise "Server error with code #{resp.code}"
    end
  end
end
