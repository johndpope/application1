require 'rails_helper'

RSpec.describe Industry, type: :model do
  let(:industry) {Industry.new}

  describe '.attributes' do
    %w(id code name).each do |a|
      it(a) { expect(industry).to respond_to(a) }
    end
  end
end
