json.array!(@client_landing_pages) do |client_landing_page|
  json.extract! client_landing_page, :id
  json.url client_landing_page_url(client_landing_page, format: :json)
end
