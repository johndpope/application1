require 'rails_helper'

RSpec.describe EmailAccountsSetup, type: :model do
  let(:email_accounts_setup) { EmailAccountsSetup.new }

 describe '.attributes' do
  %w(accounts_number channels_per_account additional_channels_reason
    gplus_business_pages_per_account additional_business_pages_reason
    cities counties boroughs states country_id top_cities_filter population_filter
    package locality_type contract_id client_id approved use_dids_for_channels).each do |a|
      it(a) { expect(email_accounts_setup).to respond_to(a) }
    end
  end
end
