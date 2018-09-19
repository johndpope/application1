require 'rails_helper'

RSpec.describe Client, type: :model do
  let(:client) {Client.new}

  describe '.attributes' do
    %w(id name country region
      locality zipcode email website parent_id industry_id
      address1 address2 phones fax
      facebook_url google_plus_url linkedin_url pinterest_url
      instagram_url blog_url notes twitter_url protected_words is_active).each do |a|
      it(a) { expect(client).to respond_to(a) }
    end
  end
end
