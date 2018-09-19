namespace :db do
  namespace :seed do
    task :import_ip_addresses => :environment do
      puts "import ip addresses task started"
			ActiveRecord::Base.transaction do
	      CSV.foreach('db/ip_addresses.csv',{:headers=>true,:col_sep=>','}) do |row|
	        params = {}
	        params[:country_id] = Geobase::Country.where("LOWER(code) = ?",row[0].downcase).first.id
	        socket = row[2].strip.split(":")
	        params[:address] = socket.first
					params[:port] = socket.second
	        params[:rating] = row[13].try(:to_f)
	        IpAddress.create(params)
	      end
				email_accounts = EmailAccount.where("ip is not null")
				email_accounts.each do |email_account|
					ip_address = IpAddress.find_by_address(email_account.ip)
					if ip_address.present?
						email_account.ip_address = ip_address
						email_account.save
					end
				end
			end
      puts "import ip addresses task finished"
    end
  end
end
