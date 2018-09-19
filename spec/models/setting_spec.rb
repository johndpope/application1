require 'rails_helper'

RSpec.describe Setting, type: :model do
  let(:setting) {Setting.new}
  describe '.attributes' do
    %w(name value description).each do |a|
      it(a) { expect(setting).to respond_to(a)}
    end
  end
end
