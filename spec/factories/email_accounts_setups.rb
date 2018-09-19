FactoryGirl.define do
  factory :email_accounts_setup do
    accounts_number { rand(100) }
    contract
  end
end
