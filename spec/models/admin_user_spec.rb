require 'rails_helper'

RSpec.describe AdminUser do
  describe '.attributes' do
    let(:admin_user) { FactoryGirl.build(:admin_user) }

    %w(client_id client).each do |attribute|
      it(attribute) { expect(admin_user).to respond_to(attribute) }
    end
  end
end
