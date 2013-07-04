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

create_a_producer
