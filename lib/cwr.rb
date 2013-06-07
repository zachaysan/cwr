class CWR
  include HTTParty

  attr_accessor :access_token

  def webhook
    require_access_token
  end

  protected

  def require_access_token
    raise "access_token required for webhook" unless access_token
  end
end
