require 'rails_helper'

RSpec.describe Artifacts::Image, type: :feature do
  let(:admin_user) { FactoryGirl.create(:admin_user) }

  before { sign_in(admin_user) }

  describe '#show' do
    let(:image) { FactoryGirl.create(:artifacts_image) }

    it 'displays the detailed info about an image' do
      visit artifacts_image_path(image)
      expect(find(:xpath, "//img[@src='#{image.file.url(:thumb)}']")).to_not be_nil
      expect(page).to have_selector('h1', text: image.title.truncate(80, separator: ' '))
      expect(page).to have_xpath("//a[@href='#{image.url}']")
      expect(page).to have_xpath("//a[@href='#{image.page_url}']")
      expect(page).to have_xpath("//a[@href='#{image.file.url}']")
      image.tag_list.each do |tag|
        expect(page).to have_selector('.label', text: tag)
      end
      expect(page).to have_link(image.license_name, href: image.license_url)
    end
  end

  describe '#index' do
    let!(:images) { FactoryGirl.create_list(:artifacts_image, 1 + rand(4)) }

    context 'when mouseover the image' do

      it 'displays tag list', js: true do
        visit artifacts_images_path
        image = images.last
        button = first("a.tags-toggle")
        hover(button)
        image.tag_list.each do |tag|
          expect(page).to have_selector('.label', text: tag)
        end
      end
    end
  end

  describe '#edit' do
    let!(:image) { FactoryGirl.create(:artifacts_image) }
    let(:new_tags) { Faker::Lorem.words }

    it 'updates image record', js: true do
      visit artifacts_images_path
      first('a[title=Edit]').click
      fill_in 'Tag list', with: new_tags.join(', ')
      click_button 'Update'
      wait_for_ajax 0.5
      expect(image.reload.tag_list.sort).to eq(new_tags.sort.uniq)
    end
  end

  describe '#destroy' do
    let!(:image) { FactoryGirl.create(:artifacts_image) }

    it 'destroys image record', js: true do
      visit artifacts_images_path
      expect {
        first('a[title=Delete]').click
        wait_for_ajax 0.5
      }.to change(Artifacts::Image, :count).by(-1)
      expect(page).to_not have_selector("#artifacts_image_#{image.id}")
    end
  end
end
