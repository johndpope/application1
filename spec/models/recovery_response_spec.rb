require 'rails_helper'

RSpec.describe RecoveryResponse, type: :model do
  let(:recovery_response) {RecoveryResponse.new}

  describe '.attributes' do
    %w(resource_id resource_type response).each do |a|
      it(a) { expect(recovery_response).to respond_to(a) }
    end
  end
end
