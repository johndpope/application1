module Requests
  extend ActiveSupport::Concern
  def remote_ip_address
    request.env['HTTP_X_FORWARDED_FOR'].to_s.split(",").first || request.remote_ip
  end
end
