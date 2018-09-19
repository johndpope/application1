class Batch < ActiveRecord::Base
  def email_accounts_size
    self.email_account_ids.strip.split(",").map(&:to_i).size
  end

  def email_accounts
    self.email_account_ids.present? ? EmailAccount.where(id: self.email_account_ids.strip.split(",").map(&:to_i)) : []
  end

  def execute_query
    self.query.present? && self.executable_query ? eval(self.query) : nil
  end

  def email_accounts_url
    Rails.application.routes.url_helpers.email_accounts_path(id: self.email_account_ids.split(",").map(&:strip).join(","))
  end

  def email_accounts_json
    Rails.application.routes.url_helpers.email_accounts_path(id: self.email_account_ids.split(",").map(&:strip).join(","), limit: self.email_account_ids.split(",").size, format: :json)
  end
end
