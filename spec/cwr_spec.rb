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
    
    producer_name = "example.com"
    @producer = @cwr.create_producer(producer_name)
  end
  
  subject { @cwr }
  specify { @cwr.yeearr }

  describe "producers" do
    subject { @producer }
    it { should be_a Producer }
    specify { @cwr.list_producers.first.should be_a Producer }
  end

  describe "consumers" do
    before(:all) do
      consumer_name = "sally from accounting"
      @consumer = @cwr.create_consumer(@producer,
                                       consumer_name)
    end
    subject { @consumer }
    it { should be_a Consumer }
    specify { @cwr.list_consumers(@producer).first.should be_a Consumer }
    specify { @consumer.destroy.should be_a DestroyedConsumer }
  end

  describe "webhooks" do
    before(:all) do
      consumer_name = "frank from accounts"
      @consumer = @producer.create_consumer(consumer_name)
      @post_data = { "strike" => "at midnight" }
      # https is both mandatory and implied
      @webhook_post_uri = "http://0.0.0.0:3000/echos"
    end
    describe "headerless webhooks" do
      before(:all) do    
        @webhook = @producer.create_webhook(@consumer,
                                            @webhook_post_uri,
                                            @post_data)
      end
      subject { @webhook }
      it { should be_a Webhook }
      specify { @webhook.hooked?.should be true }
      specify { @producer.destroy.should be_a DestroyedProducer }
      it "should update the webhook" do
        back_then = Time.now.to_i
        while Time.now.to_i < back_then + 2 and not @webhook.complete?
          sleep 0.1
          @webhook.update
        end
        @webhook.complete?.should be true
      end
    
    end
    it "should allow custom headers to be set" do
      @post_data = {"message" => "Crank"}
      @custom_headers = {"SecretKnock" => "KnockKNOCK"}
      # We can also create webhooks from the consumer directly
      @webhook = @consumer.create_webhook(@webhook_post_uri, @post_data, @custom_headers)
      back_then = Time.now.to_i
      while Time.now.to_i < back_then + 2 and not @webhook.complete?
        sleep 0.1
        @webhook.update
      end
      @webhook.complete?.should be true
    end
  end

  after(:all) do
    @cwr.list_producers do |producer|
      producer.destroy
    end
  end
end
