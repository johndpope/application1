json.array!(@ip_addresses) do |ip_address|
  json.extract! ip_address, :id, :address, :port, :rating
end
