require 'rails_helper'

RSpec.describe IpAddress, type: :model do
  let(:ip_address) {IpAddress.new}

  describe '.attributes' do
    %w(id address port rating last_assigned_at country_id stage1 stage2 stage3 stage4 stage5 address_target additional_use description).each do |a|
      it(a) { expect(ip_address).to respond_to(a) }
    end
  end
end
