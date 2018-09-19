FactoryGirl.define do
  factory :artifacts_author, :class => 'Artifacts::Author' do
    name { Faker::Name.name }
    username { Faker::Internet.user_name(name) }
    url { Faker::Internet.url }
    source_id { SecureRandom.hex.first(8) }
  end
end
