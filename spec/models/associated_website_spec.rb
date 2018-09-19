require 'rails_helper'

RSpec.describe AssociatedWebsite, type: :model do
  let(:associated_website) {AssociatedWebsite.new}

  describe '.attributes' do
    %w(client_landing_page_id youtube_channel_id ready linked dns_record association_method).each do |a|
      it(a) { expect(associated_website).to respond_to(a) }
    end
  end
end
