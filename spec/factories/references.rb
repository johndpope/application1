FactoryGirl.define do
  factory :reference do
    url { Faker::Internet.url }
    description { Faker::Lorem.sentence }
  end
end
