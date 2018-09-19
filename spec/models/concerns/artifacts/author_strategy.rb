require 'rails_helper'

shared_examples_for 'artifacts author strategy' do

  it 'extends the Artifacts::Author model' do
    author = described_class.new
    expect(author).to be_a(Artifacts::Author)
  end
end
