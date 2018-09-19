namespace :db do
  namespace :seed do
    task :import_phone_providers => :environment do
      puts "import phone providers task started"
      CSV.foreach('db/phone_providers.csv',{:headers=>false,:col_sep=>';'}) do |row|
        PhoneProvider.create(name: row[0].strip) if !PhoneProvider.find_by_name(row[0].strip).present? && row[0].present?
      end
      puts "import phone providers task finished"
    end
  end
end
