json.array!(@social_accounts) do |social_account|
  json.extract! social_account, :id
  json.url social_account_url(social_account, format: :json)
end
