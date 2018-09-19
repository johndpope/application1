json.id @client.id
json.name @client.name
json.logo_url @client.logo.present? ? Rails.configuration.routes_default_url_options[:host] + @client.logo.url : ""
