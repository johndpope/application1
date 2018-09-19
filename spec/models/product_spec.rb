require 'rails_helper'

RSpec.describe Product, type: :model do
  let(:product) {Product.new}

  describe '.attributes' do
    %w(id name client logo protected_words).each do |a|
      it(a) { expect(product).to respond_to(a) }
    end
  end
end
