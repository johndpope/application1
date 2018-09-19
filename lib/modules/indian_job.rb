require 'csv'
require 'pg'
require 'utils'

module IndianJob
	def step1_import_3000_us_gmails()
		CSV.foreach('db/indian_job/step1_3000_us_accounts.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {
				:email=>row[1].strip,
				:password=>row[2],
				:phone=>row[3],
				:recovery_email=>row[5],				
				:state=>row[12].strip,
				:city=>row[11].strip
			}
						
			GoogleAccount.create(params) if(GoogleAccount.find(:first,:conditions=>["lower(email) = ?",row[0].downcase]).nil?)
			puts params
		end				
		puts 'import has finished'
	end

	def step2_import_linked_spreadsheet()
		puts 'Step2. Importing spreadsheet with linked gmails'

		conn = PG::Connection.new({:port=>5432,:host=>'192.168.123.11',:dbname=>'broadcaster', :user=>'postgres', :password=>'changeme'})	

		CSV.foreach('db/indian_job/Top 3000 US City Gmail Accounts for YouTube Verification (Completed by Rajesh 011514).csv',{:headers=>false,:col_sep=>';'})do |row|
			params = {
				:email=>row[1],
				:email_password=>row[2],
				:email_recovery_email=>row[3],
				:email_phone=>row[4],
				:email_state=>row[9].strip,
				:email_city=>row[10].strip,
				:email_youtube_channel=>row[8],
				:linked_email=>row[5],
				:linked_email_password=>row[6],
				:linked_email_phone=>row[7]
			}		
			
			conn.exec_params('INSERT INTO linked_gmails(gmail,gmail_password,gmail_recovery_email,gmail_phone,gmail_state, gmail_city, gmail_youtube_channel_name, linked_gmail, linked_gmail_password, linked_gmail_phone) VALUES($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)',[params[:email],params[:email_password],params[:email_recovery_email],params[:email_phone],params[:email_state],params[:email_city],params[:email_youtube_channel],params[:linked_email],params[:linked_email_password],params[:linked_email_phone]])

			puts params
		end				

		puts 'import has finished'
	end

	def step3_import_linked_gmails()
		puts 'Step 3. Importing linked gmails'

		CSV.foreach('db/indian_job/Top 3000 US City Gmail Accounts for YouTube Verification (Completed by Rajesh 011514).csv',{:headers=>false,:col_sep=>';'})do |row|
			params = {
				:email=>row[5].strip,
				:password=>row[6],
				:phone=>row[7],
				:state=>row[9].strip,
				:city=>row[10].strip
			}
						
			GoogleAccount.create(params) if(GoogleAccount.find(:first,:conditions=>["lower(email) = ?",row[5].downcase.strip]).nil?)			
			puts params
		end				
		puts 'Import has finished'
	end

	def step4_import_53_gmails()
		puts 'Step 4. Imorting 53 gmails'

		CSV.foreach('db/indian_job/53 Gmail Accounts with Youtube Channels.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {
				:email=>row[0].strip.downcase,
				:password=>row[1],
				:phone=>row[2],
				:is_active=>false,
				:account_type=>1,
				:google_status=>1
			}
						
			GoogleAccount.create(params) if(GoogleAccount.find(:first,:conditions=>["lower(email) = ?",params[:email]]).nil?)
			puts params
		end				

		puts 'import completed'
	end

	def step5_import_10_test_gmails()
		puts 'Step 5. Importing 10 test gmails'
		CSV.foreach('db/indian_job/10 Test Gmail Accounts with Youtube Channels.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {
				:email=>row[0].strip.downcase,
				:password=>row[1],
				:phone=>row[2],
				:is_active=>false,
				:account_type=>3,
				:google_status=>1
			}
						
			GoogleAccount.create(params) if(GoogleAccount.find(:first,:conditions=>["lower(email) = ?",params[:email]]).nil?)
			puts params
		end				

		puts 'import completed'
	end

	def step6_import_7000_us_gmails()				
		puts 'Step 6. Importing 7000 us gmails'
		i = 0
		CSV.foreach('db/indian_job/yotube_channels_generated_for_7000_us_locations.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {
				:city=>row[0],
				:state=>row[1],
				:email=>row[4],
				:password=>row[5],
				:phone=>row[6],
				:google_status=>1,
				:account_type=>1,
			}
			
			if(GoogleAccount.find(:first,:conditions=>["lower(email) = ?",row[0].downcase]).nil?)
				GoogleAccount.create(params)
				i = i+1 
				puts "added #{params}"				
			else
				puts "ignored #{params}"
			end
		end				
		puts "Import has finished. Totally #{i} records imported"
	end

	def step7_import_international_gmail_accounts()
		puts 'Step 7. Importing international gmail Accounts'

		date_format = '%m%d%Y'

		created_count = 0
		ignored_count = 0
		
		CSV.foreach('db/indian_job/step7_international_gmail_accounts.csv',{:headers=>false,:col_sep=>';'})do |row|						
			params = {
				:email=>row[6].downcase,
				:password=>row[7],
				:city=>row[1],
				:state=>row[2],
				:first_name=>row[3],
				:last_name=>row[4],
				:birth_date=>Utils::parse_date(row[8]),
				:phone=>row[10],
				:recovery_email=>row[11]
			}
			
			google_account = GoogleAccount.find(:first,:conditions=>["lower(email) = ?",params[:email].downcase])

			if google_account.nil?				
				GoogleAccount.create(params) 
				created_count = created_count+1
				puts "created #{params}"
			else
				puts "ignored #{params}"
				ignored_count  = ignored_count+1				
			end
		end

		puts "import has finished. #{created_count} gmails were imported, #{ignored_count} gmails were ignored"
	end

	def step8_remove_non_ascii_gmails()
		puts 'Step 8. Removing gmails with non ASCII characters'
		
		gmails = GoogleAccount.all()
		non_ascii_gmails = gmails.select{|gmail| not Utils::is_ascii(gmail.email)}
		
		if(!non_ascii_gmails.nil?)			
			non_ascii_gmails.each do |non_ascii_gmail|
				puts "removing #{non_ascii_gmail.email}"
				GoogleAccount.delete(non_ascii_gmail.id)
			end						
		end		

		puts "removal has completed. #{non_ascii_gmails.length} gmails were removed"
	end

	def step9_import_repaired_inaccessible_gmails()						
		puts 'Step 9. Import rapaired inaccessible gmails'

		CSV.foreach('db/indian_job/step9_684_revised_accounts.csv',{:headers=>true,:col_sep=>';'})do |row|			
			params = {
				:email=>row[0],
				:password=>row[1],								
				:recovery_email=>row[2],
				:phone=>row[3]
			}
			
			ga = GoogleAccount.find(:first,:conditions=>["lower(email) = ?",params[:email].downcase])
			
			if(!ga.nil? && ga.password != params[:password])
				ga.update({:password=>params[:password]})
				puts "updated #{params}"				
			elsif(!ga.nil? && ga.password == params[:password])
				puts "ignored #{params}"
			else				
				GoogleAccount.create(params)
				puts "created #{params}"
			end			
		end
		
		puts 'import has finished'
	end

	def step10_import_49_repaired_inaccessible_gmails()				
		puts 'Step 10. Import repaired inaccessible gmails'

		created_count = 0
		updated_count = 0

		CSV.foreach('db/indian_job/step10_49_repaired_inaccessible_gmail_accounts.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {
				:email=>"#{row[0]}@gmail.com".downcase,
				:password=>row[1],
				:phone=>row[2],
				:recovery_email=>row[3]
			}
			
			ga = GoogleAccount.find(:first,:conditions=>["lower(email) = ? OR lower(email) = ?",row[0].downcase, params[:email]])

			if(!ga.nil? && ga.password != params[:password])
			elsif (!ga.nil? && ga.password == params[:password])
				ga.update({:email=>params[:email]})
				updated_count = updated_count+1
				puts "updated #{params}"
			else
				GoogleAccount.create(params)
				created_count = created_count+1
				puts "created #{params}"
			end			
		end		

		puts "Import has finished. #{created_count} created gmails, #{updated_count} updated gmails"		
	end

	def step11_determine_gmails_statuses
		puts 'Step 7. Determining gmails statuses'
		active_count = 0
		disabled_count = 0
		wrong_count = 0
		verification_required_count = 0

		CSV.foreach('db/indian_job/step11_google_accounts_with_tmriordan_recovery_email_status1.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {				
				:email=>row[0].downcase,
				:password=>row[1]				,
				:google_status=>1
			}
			
			google_account = GoogleAccount.find(:first,:conditions=>["lower(email) = ? AND password = ?",params[:email], params[:password]])
			if(!google_account.nil?)				
				google_account.update(params)
				active_count = active_count+1 
				puts "gmail is active #{params}"				
			else
				puts "cannot find #{params}"
			end
		end				

		CSV.foreach('db/indian_job/step11_google_accounts_with_tmriordan_recovery_email_status2.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {				
				:email=>row[0].downcase,
				:password=>row[1]				
			}
			
			google_account = GoogleAccount.find(:first,:conditions=>["lower(email) = ? AND password = ?",params[:email], params[:password]])
			if(!google_account.nil?)				
				google_account.update(params)
				disabled_count = disabled_count+1 
				puts "gmail is disabled by google #{params}"				
			else
				puts "cannot find #{params}"
			end
		end				

		CSV.foreach('db/indian_job/step11_google_accounts_with_tmriordan_recovery_email_status3.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {				
				:email=>row[0].downcase,
				:password=>row[1]				,
				:google_status=>3
			}
			
			google_account = GoogleAccount.find(:first,:conditions=>["lower(email) = ? AND password = ?",params[:email], params[:password]])
			if(!google_account.nil?)				
				google_account.update({:google_status=>3})
				wrong_count = wrong_count+1 
				puts "gmail has wrong credentials #{params}"				
			else
				puts "cannot find #{params}"
			end
		end				
		
		CSV.foreach('db/indian_job/step11_inaccessible_linked_gmails.csv',{:headers=>true,:col_sep=>';'})do |row|
			params = {				
				:email=>row[0].downcase,
				:password=>row[1]				,
				:google_status=>row[2]
			}
			
			google_account = GoogleAccount.find(:first,:conditions=>["lower(email) = ? AND password = ?",params[:email], params[:password]])
			if(!google_account.nil?)				
				google_account.update(params)				
				case params[:google_status]
					when 2
						wrong_count = wrong_count+1
					when 3
						disabled_count = disabled_count+1
					when 4
						verification_required_count = verification_required_count+1
				end
				puts "gmail has wrong credentials #{params}"				
			else
				puts "cannot find #{params}"
			end
		end				

		puts "Determination has finished. Totally #{active_count} active emails, #{disabled_count} disabled emails, #{wrong_count} emails with wrong credentials, #{verification_required_count} with required phone verification were determined"
	end

	def step12_strip_gmails_localities()
		puts 'Step 12. Removing spaces at the beginning and end of gmails localities'
		
		google_accounts = GoogleAccount.all()
		
		google_accounts.each do |ga|
			if(!ga.city.nil?)				
				ga.update(:city=>ga.city.strip())
				puts ga.city.strip()				
			end
		end

		puts 'Strip has completed'
	end

	def set_locality_id_to_gmails()
		puts 'Setting locality_id to gmails'
		updated_count = 0
		google_accounts = GoogleAccount.where('locality_id IS NULL AND state IS NOT NULL AND city IS NOT NULL')
		
		if(!google_accounts.nil?)
			google_accounts.each do |ga|				
				location = Geobase::Locality.joins(:primary_region)
					.where("lower(geobase_localities.name) = ? AND lower(geobase_regions.name) = ?",ga.city.downcase,ga.state.downcase).first				
				if(!location.nil?)	
					ga.update({:locality_id=>location.id})
					puts "updated #{ga.email} | #{ga.city} | #{ga.state}"
					updated_count = updated_count+1
				else
					puts "ignored #{ga.email} | #{ga.city} | #{ga.state}"
				end
			end
		end

		puts "Process has finished. #{updated_count} gmails updated"
	end

	module_function :step1_import_3000_us_gmails,
		:step2_import_linked_spreadsheet,
		:step3_import_linked_gmails, 		
		:step4_import_53_gmails,
		:step5_import_10_test_gmails,		
		:step6_import_7000_us_gmails,
		:step7_import_international_gmail_accounts,
		:step8_remove_non_ascii_gmails,		
		:step9_import_repaired_inaccessible_gmails,
		:step10_import_49_repaired_inaccessible_gmails, 
		:step11_determine_gmails_statuses,
		:step12_strip_gmails_localities,
		:set_locality_id_to_gmails
end