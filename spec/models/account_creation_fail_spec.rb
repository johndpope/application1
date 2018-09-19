require 'rails_helper'

RSpec.describe AccountCreationFail, type: :model do
  let(:account_creation_fail) { AccountCreationFail.new }

 describe '.attributes' do
  %w(email reason phone ip user_agent).each do |a|
      it(a) { expect(account_creation_fail).to respond_to(a) }
    end
  end
end
