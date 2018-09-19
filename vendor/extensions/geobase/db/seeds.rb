items = {
  countries: %w(id code name woeid),
  regions: %w(id code name woeid level country_id parent_id motto flower bird nicknames nickname_explanation),
  localities: %w(id code name woeid population locality_type nicknames primary_region_id),
  zip_codes: %w(id code latitude longitude primary_region_id secondary_region_id),
  localities_zip_codes: %w(locality_id zip_code_id),
  landmarks: %w(id name woeid latitude longitude country_id region_id locality_id)
}

items.each do |table, columns|
  rc = ActiveRecord::Base.connection.raw_connection
  rc.copy_data "COPY geobase_#{table}(#{columns.map(&:inspect).join(', ')}) FROM STDOUT" do
    File.open("#{File.dirname(__FILE__)}/#{table}.txt").each { |line| rc.put_copy_data line }
  end
end
