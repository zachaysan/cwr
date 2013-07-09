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
  create_a_producer unless @cwr.list_producers.length > 0
  @cwr.list_producers.first.create_consumer(consumer_name)
end

#create_a_producer

create_a_consumer
