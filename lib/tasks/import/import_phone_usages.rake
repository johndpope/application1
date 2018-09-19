namespace :db do
  namespace :seed do
    task :import_phone_usages => :environment do
      puts "import phone usages task started"
      CSV.foreach('db/sms_reg_stats.csv',{:headers=>false,:col_sep=>';'}) do |row|
        params = {}
        params[:phone] = row[0]
        params[:error_type] = row[1].present? ? row[1].try(:to_i) : nil
        params[:sms_code] = row[2]
        params[:amount] = row[3].try(:to_f)
        params[:created_at] = row[4].present? ? DateTime.strptime(row[4], '%d.%m.%Y %H:%M') : Time.now
        params[:service] = "SMS-REG"
        params[:service_account] = "valynteen"
        params[:web_service_type] = 1
        params[:source_type] = 2
        PhoneUsage.create_from_params(params)
      end
      CSV.foreach('db/sms_area_stats.csv',{:headers=>false,:col_sep=>';'}) do |row|
        params = {}
        params[:phone] = row[0]
        params[:error_type] = row[1].present? ? row[1].try(:to_i) : nil
        params[:sms_code] = row[2]
        params[:amount] = row[3].try(:to_f)
        params[:created_at] = row[4].present? ? DateTime.strptime(row[4], '%d.%m.%Y %H:%M') : Time.now
        params[:service] = "SMS-AREA"
        params[:service_account] = "valynteensolutions@gmail.com"
        params[:web_service_type] = 1
        params[:source_type] = 2
        PhoneUsage.create_from_params(params)
      end
      puts "import phone usages task finished"
    end
  end
end
