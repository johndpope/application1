require 'rails_helper'

RSpec.describe Artifacts::Author, type: :model do

  let(:author) { Artifacts::Author.new }

  describe '.attributes' do
    %w(id source_id name username url avatar type).each do |a|
      it(a) { expect(author).to respond_to(a) }
    end
  end
end
