require 'rails_helper'

shared_examples_for 'image artifact features' do

  let(:admin_user) { FactoryGirl.create(:admin_user) }

  describe 'search & import' do
    let(:query) { 'skylines' }
    let(:city) { Geobase::Locality.order('random()').first }
    let(:region1) { city.primary_region }
    let(:region2) { city.secondary_regions.first }
    let(:country) { city.country }
    let(:tags) { Faker::Lorem.words }

    before {
      Delayed::Worker.delay_jobs = true
      # Substitute remote URLs with a local image
      `cp #{Rails.root}/spec/fixtures/files/girl.jpg #{Rails.root}/public/`
      Artifacts::Image.class_eval do
        def url
          server = [Capybara.server_host, Capybara.server_port].compact.join(':')
          "http://#{server}/girl.jpg"
        end
      end
    }
    after  {
      Delayed::Worker.delay_jobs = false
      # Undo the substitution of remote URLs with a local image
      `rm #{Rails.root}/public/girl.jpg`
      Artifacts::Image.class_eval do
        def url
          read_attribute(:url)
        end
      end
    }

    it 'displays the images and allows to import them', vcr: true, js: true do
      sign_in(admin_user)

      visit artifacts_images_path
      type = described_class.to_s.demodulize.gsub('Image', '')
      find('#api-switch .dropdown-toggle').click
      click_link type
      fill_in 'q', with: query
      find('body').click
      expect(page).to have_selector('ins.iCheck-helper')
      page.execute_script "$('.artifacts_image:first input[type=checkbox]').iCheck('check')"
      click_link 'Import'
      page.execute_script %Q[
        $('#city').select2(
          'data',
          { id: '#{city.id}', text: '#{city.name}, #{region1.name} #{country.code}' }
        ).trigger('change')
      ]
      wait_for_ajax(1)
      # Expect country, region1 and region2 to be autopopulated after selecting
      # a city
      expect(find('#country', visible: false).value).to eq(country.id.to_s)
      expect(page).to have_selector("#s2id_country .select2-chosen", text: country.name)
      expect(find('#region1', visible: false).value).to eq(region1.id.to_s)
      expect(page).to have_selector("#s2id_region1 .select2-chosen", text: region1.name)
      if region2
        expect(find('#region2', visible: false).value).to eq(region2.id.to_s)
        expect(page).to have_selector("#s2id_region2 .select2-chosen", text: region2.name)
      end

      fill_in 'tag_list', with: tags.join(', ')
      expect {
        click_button 'Continue'
        wait_for_ajax 0.5
      }.to change { Delayed::Job.count }.by(1)
      expect(Artifacts::Image.last.admin_user_id).to eq(admin_user.id)
      within first('.artifacts_image') do
        expect(page).to_not have_selector('input[type=checkbox]')
        expect(page).to have_selector('.label.label-success', text: 'IMPORTING ...')
      end
     end
  end
end
