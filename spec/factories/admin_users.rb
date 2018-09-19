FactoryGirl.define do
  factory :admin_user do
    email { Faker::Internet.email }
    password { ('0'..'z').to_a.shuffle.first(8).join }
    password_confirmation { password }
  end
end
