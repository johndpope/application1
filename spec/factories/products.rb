FactoryGirl.define do
  factory :product do
    name { Faker::Commerce.product_name }
    client
  end
end
