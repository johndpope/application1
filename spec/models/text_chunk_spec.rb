require 'rails_helper'

RSpec.describe TextChunk, type: :model do
  let(:text_chunk) {TextChunk.new}
  describe '.attributes' do
    %w(chunk_type value).each do |a|
      it(a) { expect(text_chunk).to respond_to(a) }
    end
  end
end
