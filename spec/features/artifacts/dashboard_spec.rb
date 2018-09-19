require 'rails_helper'

RSpec.describe 'Dashboard', type: :feature do
  include ArtifactsHelper

  let(:admin_user) { FactoryGirl.create(:admin_user) }

  before do
    FactoryGirl.create_list(:artifacts_image, 1 + rand(10))
    sign_in(admin_user)
    click_link 'Artifacts'
  end

  it 'remembers sidebar state', js: true do
    find('a.sidebar-toggle').click
    expect(page).to have_css('body.sidebar-collapse')
    visit artifacts_root_path
    expect(page).to have_css('body.sidebar-collapse')
  end

  it 'has session navigation', js: true do
    within 'header nav' do
      expect(page).to have_text(admin_user.username)
      click_link admin_user.username
      expect(page).to have_link('Sign Out', href: destroy_admin_user_session_path)
    end
  end

  it 'has quick links', js: true do
    within 'section.sidebar' do
      click_link 'Images'
      click_link 'Quick Links'
      click_link 'Tags'
      expect(page).to have_link(popular_image_tags.shuffle.first)
      click_link 'Places'
      expect(page).to have_link(popular_image_places.shuffle.first)
    end
  end

  it 'has the link to the main page' do
    expect(page).to have_link('Dashboard', root_path)
  end

  describe 'statistics' do
    let(:total_images) { Artifacts::Image.where.not(file_file_name: nil).count }
    let(:states_covered) {
      Artifacts::Image.where.not(region1: nil).select('DISTINCT region1').count
    }
    let(:counties_covered) {
      Artifacts::Image.where.not(region2: nil).select('DISTINCT region2').count
    }
    let(:cities_covered) {
      Artifacts::Image.where.not(city: nil).select('DISTINCT city').count
    }

    it 'shows the counts and coverage' do
      visit artifacts_root_path
      within '#img-total' do
        expect(page).to have_text(total_images)
      end
      within '#img-region1-cov' do
        expect(page).to have_text(states_covered)
      end
      within '#img-region2-cov' do
        expect(page).to have_text(counties_covered)
      end
      within '#img-city-cov' do
        expect(page).to have_text(cities_covered)
      end
    end
  end
end
