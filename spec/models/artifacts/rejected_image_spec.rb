require 'rails_helper'

RSpec.describe Artifacts::RejectedImage, type: :model do
  let(:rejected_image) {Artifacts::RejectedImage.new}

  describe '.attributes' do
    %w(source_id source_type).each do |a|
      it(a) { expect(rejected_image).to respond_to(a) }
    end
  end
end
