require 'rails_helper'
require 'models/concerns/tenantable'

RSpec.describe Artifacts::Image, type: :model do
  let(:image) { FactoryGirl.build(:artifacts_image) }

  it_behaves_like 'tenantable'

  describe '.attributes' do
    attributes = [
      'id', 'url', 'file', 'author', 'width', 'height', 'title', 'lat', 'lng',
      'country', 'region1', 'region2', 'city', 'license_name', 'license_code',
      'license_url', 'page_url', 'source_id', 'type', 'width', 'height',
      'admin_user_id', 'admin_user', 'source_tag_list'
    ]
    attributes.each { |a| it(a) { expect(image).to respond_to(a) } }
  end

  it '#width & #height are automatically set from #file' do
    geometry = Paperclip::Geometry.from_file(image.file.staged_path)
    width = geometry.width.to_i
    height = geometry.height.to_i

    image.save!
    expect(image.width).to eq(width)
    expect(image.height).to eq(height)

    image.file = nil
    image.save!
    expect(image.width).to be_nil
    expect(image.height).to be_nil
  end

  describe '.full_text_search' do
    
    before(:all) { FactoryGirl.create_list(:artifacts_image, 10, file: nil) }
    after(:all) { Artifacts::Image.destroy_all }

    let(:image) { Artifacts::Image.order('random()').first }
    let(:tag) { image.tag_list.first }
    let(:city) { image.city }
    let(:region2) { image.region2 }
    let(:region1) { image.region1 }
    let(:country) { image.country }
    let(:title) { image.title }

    %w(tag city region2 region1 country title).each do |field|
      it "finds images by #{field}" do
        expect(Artifacts::Image.full_text_search(send(field))).to include(image)
      end
    end
  end

  describe 'distribution' do

    describe 'by region1' do
      before do
        2.times {
          FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'California')
        }
        FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'New York')
      end
      let(:counts) { { 'California, United States of America' => 2, 'New York, United States of America' => 1 } } 

      it('counts records by region1') { expect(Artifacts::Image.distribution_by_region1).to eq(counts) }
    end

    describe 'by city' do
      before do
        2.times do
          FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'California',
                             city: 'San Diego')
        end
        FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'New York',
                           city: 'New York')
      end
      let(:counts) { { 'San Diego, California' => 2, 'New York, New York' => 1 } }

      it('counts records by city') { expect(Artifacts::Image.distribution_by_city).to eq(counts) }
    end

    describe 'by region2' do
      before do
        2.times do
          FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'California',
                             region2: 'Los Angeles')
        end
        FactoryGirl.create(:artifacts_image, country: 'United States of America', region1: 'New York',
                           region2: 'Jefferson')
      end
      let(:counts) { { 'Los Angeles, California' => 2, 'Jefferson, New York' => 1 } }

      it('counts records by city') { expect(Artifacts::Image.distribution_by_region2).to eq(counts) }
    end

    describe 'by tag' do
      before do
        FactoryGirl.create(:artifacts_image, tag_list: %w(one two three))
        FactoryGirl.create(:artifacts_image, tag_list: %w(two three four))
        FactoryGirl.create(:artifacts_image, tag_list: %w(fourty two))
      end
      let(:counts) { { 'two' => 3, 'three' => 2, 'four' => 1, 'fourty' => 1, 'one' => 1 } }

      it('counts records by tags') { expect(Artifacts::Image.distribution_by_tag).to eq(counts) }
    end
  end
end
