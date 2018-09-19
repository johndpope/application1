class AccountCreationFail < ActiveRecord::Base
  REASONS = {"sms failed" => 1, "phone failed" => 2, "google refused" => 3, "phone used too many times" => 4, "cannot serve request" => 5}
  extend Enumerize
  enumerize :reason, in: REASONS
end
