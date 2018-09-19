require 'rails_helper'

RSpec.describe Phone, type: :model do
  let(:phone) {Phone.new}

  describe '.attributes' do
    %w(id phone_type phone_provider_id status country_name region_name locality_name country_id region_id locality_id description value ordered_at expires_at last_assigned_at parked park_answer usable unusable_at).each do |a|
      it(a) { expect(phone).to respond_to(a) }
    end
  end
end
