require 'rails_helper'

RSpec.describe RecoveryAttemptResponse, type: :model do
  let(:recovery_attempt_response) {RecoveryAttemptResponse.new}

  describe '.attributes' do
    %w(response response_type).each do |a|
      it(a) { expect(recovery_attempt_response).to respond_to(a) }
    end
  end
end
