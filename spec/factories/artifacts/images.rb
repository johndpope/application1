FactoryGirl.define do
  factory :artifacts_image, :class => 'Artifacts::Image' do
    url { Faker::Internet.url }
    file {
      File.open(File.join(Rails.root, 'spec', 'fixtures', 'files', 'girl.jpg'))
    }
    title { Faker::Lorem.sentence }
    country { 'United States of America' }
    region1 { Geobase::Country.find_by_name(country).regions.where(level: 1).order('random()').first.name }
    region2 { Geobase::Country.find_by_name(country).regions.where(level: 2).order('random()').first.name }
    city { Geobase::Country.find_by_name(country).localities.order('random()').first.name }
    page_url { Faker::Internet.url }
    source_id { ('0'..'9').to_a.shuffle.first(6).join }
    type {
      "Artifacts::#{%w(Flickr Pixabay Iconfinder Openclipart).shuffle.first}Image"
    }
    tag_list { Faker::Lorem.words }
    license_name { Faker::Lorem.sentence }
    license_url { Faker::Internet.url }
  end
end
