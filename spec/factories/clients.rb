FactoryGirl.define do
  factory :client do
    name { Faker::Lorem.word.titleize }
    description { Faker::Lorem.paragraph }
  end
end
