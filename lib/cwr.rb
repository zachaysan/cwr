class CWR
  include HTTParty

  attr_accessor :access_token, :username, :password

  def webhook
    require_access_token

    self.class.post
  end

  protected

  def require_access_token
    create_new_access_token_if_able unless access_token
    raise "access_token required for webhook" unless access_token
  end

  def create_new_access_token_if_able
    return @username and @password and new_access_token
  end

  def new_access_token
    body = { username: @username, password: @password }
    headers = 'Content-Type' => 'application/json'

    self.class.post("access_tokens",
                    body: body.to_json,
                    headers: headers)
  end

  def securely_post(post_body, options)
    require_access_token
  end
end
