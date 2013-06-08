require 'json'
require 'httparty'

class CWR
  include HTTParty
  base_uri 'http://0.0.0.0:3000'

  attr_accessor :access_token, :email, :password, :producer
  alias_method :username, :email
  def username=(other)
    @email = other
  end
  
  def webhook
    require_access_token

    self.class.post
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

  def securely_post(post_body, options)
    require_access_token
  end
end
