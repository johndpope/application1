require 'rails_helper'

RSpec.describe GoogleAccount, type: :model do
  let(:google_account) {GoogleAccount.new}

  describe '.attributes' do
    %w(email password phone phone_owner recovery_email refresh_token
    first_name last_name city state birth_date google_status account_type
    google_api_client_id is_active client_id locality_id ip
    account_category domain alternate_email error_type adwords_id adwords_account_name
    youtube_data_api_key).each do |a|
      it(a) { expect(google_account).to respond_to(a) }
    end
  end
end
