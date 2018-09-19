require 'rails_helper'

RSpec.describe Author, type: :model do
  let(:author) { Author.new }

  it 'should have the following attributes' do
    [
      'username', 'initials', 'url', 'author_item', 'author_item_id',
      'author_item_type', 'attachment'
    ].each { |a| expect(author).to respond_to(a) }
  end
end
