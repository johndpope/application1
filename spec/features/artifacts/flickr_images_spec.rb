require 'rails_helper'
require 'features/concerns/artifacts/images_strategy'

RSpec.describe Artifacts::FlickrImage, type: :feature do
  include_examples 'image artifact features'

  describe 'custom filters' do
    let(:admin_user) { FactoryGirl.create(:admin_user) }

    before do
      sign_in(admin_user)
      visit artifacts_images_path(api: 'Flickr')
    end

    it 'has the `tags` filter', js: true do
      find('.advanced-toggle').click
      expect(page).to(have_xpath("//label[@for='tags' and text() = 'Tags']"))
      expect(page).to(
        have_xpath(
          "//textarea[@name='tags' and @placeholder='Tags']"
        )
      )
    end
  end
end
