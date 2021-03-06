require 'json'
require 'httparty'

class Producer
  attr_reader :path

  def initialize(cwr,
                 name,
                 path=nil,
                 owner_id=nil)
    @cwr = cwr
    @name = name
    @path = path
    @owner_id = owner_id
  end
  
  def destroy
    @cwr.destroy_producer(self)
    return DestroyedProducer.new(path)
  end

  def create_consumer(name)
    @cwr.create_consumer self, name
  end
  
  def create_webhook(consumer, webhook_post_uri, post_data=nil, post_headers=nil)
    @cwr.create_webhook(consumer, webhook_post_uri, post_data, post_headers)
  end

  def create_mass_webhooks
    raise "Not implemented"
  end

  def id
    @path ? @path.split("/")[-1] : nil
  end

  def list_consumers
    @cwr.list_consumers(self)
  end
end

class Consumer
  attr_reader :path

  def initialize(cwr, producer, name, consumer_path=nil)
    @cwr = cwr
    @producer = producer
    @name = name
    @path = consumer_path
  end

  def destroy
    @cwr.destroy_consumer(self)
    return DestroyedConsumer.new(path)
  end

  def id
    @path ? @path.split("/")[-1] : nil
  end

  def create_webhook(post_uri, post_data=nil, post_headers=nil)
    @producer.create_webhook(self, post_uri, post_data, post_headers)
  end
end

class Webhook
  def initialize(cwr, path, complete=false)
    @cwr = cwr
    @path = path
    @hooked = true
    @complete = complete
  end
  
  def hooked?
    raise "wtf unhookedwebhook" unless @hooked
    @hooked
  end

  def complete?
    @complete
  end

  def destroy
    @hooked = false
  end

  def update
    resp = @cwr.update_webhook(@path)
    @complete = !resp["attempt"]
  end
end

class Destroyed
  def initialize(former_path)
    @former_path = former_path
  end
end

class DestroyedProducer < Destroyed
end

class DestroyedConsumer < Destroyed
end

class DestroyedWebhook < Destroyed
end

class CWR
  include HTTParty

  attr_accessor :access_token, :email, :password, :producer
  alias_method :username, :email

  def initialize(captian_webhooks_base_uri='http://captainwebhooks.com',
                 producer_path=nil,
                 consumer_path=nil,
                 webhook_path=nil)
    @PRODUCER_PATH = producer_path || "/producers"
    @CONSUMER_PATH = consumer_path || "/consumers"
    @WEBHOOK_PATH = webhook_path || "/webhooks"
    self.class.base_uri captian_webhooks_base_uri
  end

  def username=(other)
    @email = other
  end

  def create_producer(name)
    body = { producer: { name: name } }
    resp = securely_post( @PRODUCER_PATH, body )
    
    location = resp.headers['location']
    producer_path = location.split(self.class.base_uri)[-1]
    return Producer.new( self, name, producer_path )
  end

  def create_consumer(producer, name)
    consumer = { name: name, producer_id: producer.id }
    body = { consumer: consumer }
    resp = securely_post( @CONSUMER_PATH, body )
    location = resp.headers['location']
    consumer_path = location.split(self.class.base_uri)[-1]
    return Consumer.new( self, producer, name, consumer_path )
  end

  def create_webhook(consumer, post_uri, post_data=nil, post_headers=nil)
    post_data = post_data.to_json unless post_data.is_a? String or post_data.nil?
    post_headers = post_headers.to_json unless post_headers.is_a? String or post_headers.nil?

    webhook = { post_uri: post_uri,
      post_data: post_data,
      consumer_id: consumer.id }

    webhook[:post_headers] = post_headers if post_headers

    body = { webhook: webhook }
    resp = securely_post( @WEBHOOK_PATH, body )
    location = resp.headers['location']
    webhook_path = location.split(self.class.base_uri)[-1]
    Webhook.new(self, webhook_path)
  end

  def update_webhook(webhook_path)
    securely_get( webhook_path )
  end

  def destroy_consumer(consumer)
    resp = securely_delete(consumer.path)
  end

  def destroy_producer(producer)
    resp = securely_delete(producer.path)
  end

  def list_consumers(producer, &block)
    block_given = !!block
    params = { producer_id: producer.id }
    resp = securely_get(@CONSUMER_PATH,
                        params)
    consumers = resp['consumers']
    collector = [] unless block_given
    consumers.map do |p|
      consumer = p['consumers']
      name = consumer['name']
      id = consumer['id']
      path = "#{@CONSUMER_PATH}/#{id}"
      
      consumer = Consumer.new( self, producer, name, path )

      if block_given
        yield consumer
      else
        collector << consumer
      end
    end
    return collector
  end

  def list_producers(&block)
    block_given = !!block
    params = { email: @email }
    resp = securely_get(@PRODUCER_PATH,
                        params)
    producers = resp['producers']
    collector = [] unless block_given
    producers.map do |producer|
      name = producer['name']
      id = producer['id']
      owner_id = producer['owner_id']
      path = "#{@PRODUCER_PATH}/#{id}"
      producer = Producer.new(self, name, path, owner_id)
      if block_given
        yield producer
      else
        collector << producer
      end
    end
    return collector
  end

  def create_mass_webhook(producer, consumers, post_data=nil)
    raise "NOT IMPLEMENTED"
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

  def secure_headers(headers=nil)
    headers ||= {}
    # Note that rails converts headers to HTTP_AUTHORIZATION
    # automatically, so on the server side it will not look
    # the same as the request, even if we tack on "HTTP_" 
    # ourselves.
    headers['AUTHORIZATION'] = @access_token
    headers['Content-Type'] = 'application/json'
    return headers
  end

  def http_exception(e, method, path, params=nil, body=nil)
    error = e.message + "\n"
    error += "Problem with secure #{method} to: #{path}\n"
    error += "path: #{path}\n"
    error += "body: #{body}" if body
    error += "params: #{params}" if params
    print error
    raise e
  end

  def securely_delete(path, headers=nil)
    require_access_token
    headers = secure_headers(headers)
    begin
      resp = self.class.delete(path,
                               headers: headers)
      check_response resp
    rescue Exception => e
      http_exception(e, :delete, path)
    end
    resp
  end

  def securely_get(path, params=nil, headers=nil)
    require_access_token
    headers = secure_headers(headers)

    begin
      resp = self.class.get(path, :headers => headers, :query => params)
      check_response resp
    rescue Exception => e
      http_exception(e, :get, path, params)
    end
    resp
  end

  def securely_post(path, body, headers=nil)
    require_access_token
    headers = secure_headers(headers)
    begin
      resp = self.class.post(path,
                             body: body.to_json,
                             headers: headers)
      check_response resp
    rescue Exception => e
      http_exception(e, :post, path, nil, body)
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
