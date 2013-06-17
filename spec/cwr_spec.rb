require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..',
                                   'lib',
                                   'cwr.rb'))

SPEC_EMAIL = "z@z.com"
SPEC_PASSWORD = "foo"

describe CWR, "#new_access_token" do
  it "creates an access token from email and password" do
    cwr = CWR.new
    cwr.email = SPEC_EMAIL
    cwr.password = SPEC_PASSWORD
    cwr.send(:new_access_token).length.should be > 0
  end

  it "creates an access token from email as username" do
    cwr = CWR.new
    cwr.username = SPEC_EMAIL
    cwr.password = SPEC_PASSWORD
    cwr.send(:new_access_token).length.should be > 0
  end
end

describe CWR, "Normal usage" do
  before(:all) do
    @cwr = CWR.new
    @cwr.email = SPEC_EMAIL
    @cwr.password = SPEC_PASSWORD
  end
  
  subject { @cwr }

  describe "when creating a producer" do
    before(:all) do
      producer_name = "example.com"
      @producer = @cwr.create_producer(producer_name)
    end
    subject { @producer }
    it { should be_a Producer }
    specify { @producer.destroy.should be_a DestroyedProducer }
    specify { @cwr.list_producers.first.should be_a Producer }
  end

  it "allows you to create a consumer"
  it "allows you to create a fucking webhook"

end
