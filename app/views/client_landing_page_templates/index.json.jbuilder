json.array!(@client_landing_page_templates) do |client_landing_page_template|
  json.extract! client_landing_page_template, :id
  json.url client_landing_page_template_url(client_landing_page_template, format: :json)
end
