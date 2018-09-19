FactoryGirl.define do
  factory :wording do
    name { Faker::Lorem.word }
    source 'Here is an example.'
    spintax "{Here is|Here's} {an example|a good example|an illustration}."
  end
end
