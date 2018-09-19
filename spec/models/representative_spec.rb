require 'rails_helper'

RSpec.describe Representative, type: :model do
  let(:representative) {Representative.new}

  describe '.attributes' do
    %w(id first_name mid_name last_name primary title email skype phones fax client).each do |a|
      it(a) { expect(representative).to respond_to(a) }
    end
  end
end
