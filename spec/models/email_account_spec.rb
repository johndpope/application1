require 'rails_helper'

RSpec.describe EmailAccount, type: :model do
  let(:email_account) {EmailAccount.new}

  describe '.attributes' do
    %w(email firstname lastname locality_id email_item_id
    email_item_type recovery_phone_number recovery_email secret_question
    secret_answer birth_date password country_name region_name
    locality_name is_active notes ip ip_notes is_verified_by_phone
    account_type creation_source client_id region_id email_accounts_setup_id
    deleted recovery_email_password recovery_phone_id recovery_phone_assigned_at
		recovery_phone_assigned profile_cookie user_agent_text ip_address_id had_recovery_email
    bot_server_id).each do |a|
      it(a) { expect(email_account).to respond_to(a) }
    end
  end
end
