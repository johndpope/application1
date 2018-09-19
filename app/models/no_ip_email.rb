class NoIpEmail < ActiveRecord::Base

	def self.import()
		puts 'Import of no ip emails has started'
		
		no_ip_dir = File.join(Rails.root.join('db','no_ip_emails'))
		
		imported_emails = 0;
		ignored_emails = 0;

		Dir.glob(File.join(no_ip_dir, "*.csv")) do |csv_file|
			puts "processing #{csv_file}"

			CSV.foreach(csv_file,{:headers=>true,:col_sep=>';'}) do |row|
				no_ip_email = NoIpEmail.where(email: row[0]).first
				if(no_ip_email.nil?)
					NoIpEmail.create({email:row[0],password:row[1]})
					imported_emails+=1
					puts "imported #{row[0]}"
				else
					ignored_emails+=1
					puts "ignored #{row[0]}"
				end				
			end
		end

		puts "Import of no ip emails has finished. #{imported_emails} imported emails. #{ignored_emails} ignored emails"
	end
end
