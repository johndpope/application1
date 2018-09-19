json.array!(@bot_servers) do |bot_server|
  json.extract! bot_server, :id
  json.url bot_server_url(bot_server, format: :json)
end
