require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..',
                                   'lib',
                                   'cwr.rb'))

EMAIL = "z@z.com"
PASSWORD = "foo"
@cwr = CWR.new
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
  # Note: this will only work if you have cw running locally, otherwise you will
  #       need to put in your own uri that you are sure will work

  post_uri = "http://0.0.0.0:3000/echos"

  data = {"Yeaaaar" => "Avast ye webhooks, can ye hear me?" }
  create_a_consumer unless consumer?
  
  consumer = @cwr.list_producers.map(&:list_consumers).flatten.first
  consumer.create_webhook(post_uri, data)
end

#create_a_producer
#create_a_consumer
#create_a_failed_webhook
create_a_webhook
