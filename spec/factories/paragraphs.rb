FactoryGirl.define do
  factory :paragraph do
    title { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph(4) }
    scope { Faker::Lorem.word }
  end
end
