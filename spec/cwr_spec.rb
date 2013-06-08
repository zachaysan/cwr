require File.expand_path(File.join(File.dirname(__FILE__),
                                   '..',
                                   'lib',
                                   'cwr.rb'))

SPEC_EMAIL = "w@w.com"
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
    cwr.email = SPEC_EMAIL
    cwr.password = SPEC_PASSWORD
    cwr.send(:new_access_token).length.should be > 0
  end
end
