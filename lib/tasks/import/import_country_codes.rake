namespace :db do
  namespace :seed do
    task :import_country_codes => :environment do
      puts "import country codes task started"
      CSV.foreach('db/country_codes.csv',{:headers=>false,:col_sep=>';'}) do |row|
        Geobase::Country.create(name: row[0].strip, code: row[1].strip[0..1]) if !Geobase::Country.find_by_name(row[0].strip).present? && row[0].present?
      end
      puts "import country codes task finished"
    end
  end
end
