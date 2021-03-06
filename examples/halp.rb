require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..',
                                   'lib',
                                   'cwr.rb'))

ROOT_URI = "http://0.0.0.0:3000"

EMAIL = "z@z.com"
PASSWORD = "foo"
@cwr = CWR.new(ROOT_URI)
@cwr.email = EMAIL
@cwr.password = PASSWORD



def create_a_producer
  producer_name = "Project Echelon"
  @cwr.create_producer(producer_name)
end

def create_a_consumer
  consumer_name = "Francy Pants"
  create_a_producer unless producer?
  @cwr.list_producers.first.create_consumer(consumer_name)
end

def producer?
  @cwr.list_producers.length > 0
end

def consumer?
  consumers = @cwr.list_producers.map(&:list_consumers).flatten
  consumers.length > 0
end

def create_a_failed_webhook
  # Note: this will fail since they are not set up to recieve webhooks
  post_uri = "http://www.revleft.com/"

  data = {"urgent message for our comrade!" => "We're using captain webhooks to send this to you!" }
  create_a_consumer unless consumer?
  
  consumer = @cwr.list_producers.map(&:list_consumers).flatten.first
  consumer.create_webhook(post_uri, data)
end

def create_a_webhook
  # This might not work, since /echos might not be open
  # to the public

  post_uri = "#{ROOT_URI}/echos"


  data = {"Yeaaaar" => "Avast ye webhooks, can ye hear me?" }
  create_a_consumer unless consumer?
  
  consumer = @cwr.list_producers.map(&:list_consumers).flatten.first
  consumer.create_webhook(post_uri, data)
end

#create_a_producer
#create_a_consumer
#create_a_failed_webhook
(1..10).to_a.each do
  create_a_webhook
end
