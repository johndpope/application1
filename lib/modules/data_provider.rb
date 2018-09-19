require 'csv'
require 'date'
require 'google/api_client'
require 'uri'
require 'net/http'
require 'tempfile'
require 'tmpdir'
require 'faker'
require 'random_password_generator'
require_relative '../thumbnailer/thumbnailer/generator'

module DataProvider
	def import_popular_us_languages()
		CSV.foreach('db/popular_us_languages.csv',{:headers=>true,:col_sep=>';'})do |row|
			puts row[0]
			params = {
				:name=>row[0],
				:code=>row[1],				
			}
			
			Language.create(params) if Language.find(:first,:conditions=>["lower(name) = ?",params[:name].downcase]).nil?
		end

		puts 'import has finished'
	end
	
	def get_random_case_tags()
		case_type = CaseType.find(2)
		puts case_type.get_random_tags(500,'en',70,'es',30)
	end

	def upload_youtube_video_thumbnail()
		UploadYoutubeVideoThumbnail::create(UploadYoutubeVideo.find(:last))
		upload_operation = UploadYoutubeVideoThumbnail.find(:last)
		upload_operation.perform()
	end

	def save_to_tempfile(url)
	  file = nil

	  uri = URI.parse(URI.escape(url))	  
	  Net::HTTP.start(uri.host, uri.port) do |http|
	    resp = http.get(uri.path)	    	    	    
	    
	    cur_time = Time.now
	    
	    file = File.new("#{Dir.tmpdir}/broadcaster/thumbnails/#{cur_time.strftime('%Y-%m-%d %H:%M:%S.%3N')}","w:#{resp.body.encoding}")
	    
	    begin
		  	File.open(file.path,"w:#{resp.body.encoding}") do |f|
		    	f.write(resp.body)		    	
			end
		rescue IOError => e
		  #some error occur, dir not writable etc.
		ensure
		  file.close unless file == nil
		end	    
	  end

	  return file
	end

	def import_case_types
		puts 'Starting import from legalbistro.com'
		CaseType::replicate()
		puts 'Import has finished'
	end

	def import_qualifiers
		puts 'Starting qualifiers import'
		CSV.foreach('db/qualifiers.csv',{:headers=>true,:col_sep=>';'}) do |row|
			language = Language.find(:first,:conditions=>["code = ?",row[2]])
			language_id = !language.id.nil? ? language.id : nil

			params = {
				:name=>row[0],
				:level=>row[1],
				:language_id=>language_id
			}

			if (Qualifier.find(:first,:conditions=>["name = ?",params[:name]]).nil?)
				Qualifier.create(params) 
				puts "imported #{params[:name]}"
			else
				puts "ignored #{params[:name]}"
			end
		end
		puts 'Qualifiers import has finished'
	end

	def import_tag_lines
		puts 'Starting tag lines import'
		CSV.foreach('db/tag_lines.csv',{:headers=>true,:col_sep=>';'}) do |row|						
			params = {
				:name=>row[0]
			}

			if (TagLine.find(:first,:conditions=>["name = ?",params[:name]]).nil?)
				TagLine.create(params) 
				puts "imported #{params[:name]}"
			else
				puts "ignored #{params[:name]}"
			end
		end
		puts 'Tag Line import has finished'
	end

	def generate_video_params
		google_account = GoogleAccount.find(26)
		source_video = SourceVideo.find(:first)		
		puts VideoUtils::generate_video_params(source_video,google_account)
	end

	def generate_case_type_thumbnail()
		case_type = CaseType.find(2)
		locality = Geobase::Locality.find(:first)
		Thumbnailer::Generator.new('/tmp/broadcaster/thumbnails',case_type,locality).generate()
	end

	def import_youtube_video_categories
		puts 'Starting video categories import'
		CSV.foreach('db/youtube_video_categories.csv',{:headers=>true,:col_sep=>';'}) do |row|						
			params = {
				:youtube_category_id=>row[0],
				:name=>row[1],
			}

			if (YoutubeVideoCategory.find(:first,:conditions=>["youtube_category_id = ?",params[:youtube_category_id]]).nil?)
				YoutubeVideoCategory.create(params) 
				puts "imported #{params[:name]}"
			else
				puts "ignored #{params[:name]}"
			end
		end
		puts 'Youtube video categories import has finished'
	end

	def import_tags()
		puts 'Starting tags import'	
		wrong_case_types = []

		puts Rails.root.join('db','tags','case_tags')

		Dir.glob(File.join(Rails.root.join('db','tags','case_tags'), "*")) do |f|			
			if File.directory? f
				language = Language.find(:first, conditions: ["lower(code) = ?", File.basename(f).downcase])												
				Dir.glob(File.join(f, "*.csv")) do |csv_file|
					puts "Processing #{File.basename(f)}/#{File.basename(csv_file)}"			
					CSV.foreach(csv_file,{:headers=>true,:col_sep=>';'}) do |row|													
						case_type = CaseType.where("lower(name) = ?",row[1].downcase).first
						if(!case_type.nil?)
							case_tags = get_case_tags(row)
							case_tags.each do |tag|
								if(!CaseTag.find(:first,:conditions=>["lower(name) = ? AND case_type_id = ?",tag.downcase, case_type.id]))							
									case_tag = CaseTag.create({:name=>tag, case_type_id: case_type.id, language_id: language.id})
									Tag.create({tag_id: case_tag.id, tag_type: CaseTag.name})
									
									puts "imported #{tag}"
								else
									puts "ignored #{tag}"
								end					
							end if !case_tags.empty?
						else
							wrong_case_types.push(row[1])
						end				
					end
				end				
			end
		end

		wrong_case_types.each {|case_tag| puts "Case type #{case_tag} doesnt exist"} if !wrong_case_types.empty?
				
		puts 'Tags import has finished'
	end

	def import_refresh_tokens()		
		puts 'Import of resfresh tokens started'
		CSV.foreach(File.join(Rails.root.join('db','indian_job','refresh_tokens', 'step4_1000_accounts_for_refresh_tokens.csv')),{:headers=>true,:col_sep=>';'}) do |row|						
			ip = row[8]			

			if(ip.to_s!='' || row[10].to_s!='')
				google_account = GoogleAccount.where("lower(email) = ?",row[0].downcase).first
				if(!google_account.nil?)
					if (ip && ip.downcase == 'phone verification')
					 	google_status = 4
				 	elsif (row[10] == 'The email or password you entered is incorrect.')
				 		google_status = 2
			 		elsif (row[10] == 'Disabled')
			 			google_status = 3
				 	else
				 		google_status = 1
					end
					
					channel_title = row[11]
					channel_name = (row[10].to_s!='' && !['The email or password you entered is incorrect.','There is no YouTube channel','Disabled'].include?(row[10]) ? row[10] : nil)
					
					new_password = row[6]
					recovery_email = row[7]

					thumbnails_enabled = nil					

					if(row[9].to_s!='')
						if(row[9].to_s.downcase == 'true')
							thumbnails_enabled = true
						elsif(row[9].to_s.downcase == 'false' || row[9].to_s.downcase == 'fails')
							thumbnails_enabled = false
						end
					end

					google_params = {google_status: google_status}
					if(google_status == 1)
						google_params[:password] = new_password if new_password
						google_params[:recovery_email] = recovery_email if recovery_email
						google_params[:ip] = ip if ip
						google_params[:is_active] = true
					else
						google_params[:is_active] = false
					end
					
					google_account.update(google_params)
					
					if(google_status == 1 && channel_title != 'There is no YouTube channel')					
						youtube_params = {youtube_channel_id: channel_name, 
							youtube_channel_name: channel_title, 
							is_active: true, google_account_id: google_account.id,thumbnails_enabled:thumbnails_enabled}

						youtube_channel = google_account.youtube_channels.empty? ? nil : google_account.youtube_channels.first

						if(youtube_channel)
							youtube_channel.update(youtube_params)
							puts "channel updated #{youtube_params}"
						else
							YoutubeChannel.create(youtube_params)
							puts "channel created #{youtube_params}"
						end						
					end								
				else
					puts "email #{row[0]} doesn't exists"
				end		
			end
		end		
		puts 'Import finished'
	end

	def self.test_tokens(limit)
		google_accounts = GoogleAccount.where("refresh_token is not null AND updated_at::date<>?", Time.now.strftime('%Y-%m-%d')).order("RANDOM()").limit(limit)
		google_accounts.each do |google_account|
			is_api_accessible = true
			begin
				google_account.fetch_access_token!								
			rescue Signet::AuthorizationError
				is_api_accessible = false
				google_account.is_active = false
				google_account.google_status = 3								
			end
			google_account.updated_at = Time.now
			google_account.save
			puts "#{google_account.email} #{is_api_accessible}"
			sleep(rand(1 .. 10))
		end
		nil
	end

	def create_youtube_videos()
		UploadYoutubeVideo.all().each do |upload_operation|			
			YoutubeVideo::create_or_update(upload_operation)
			puts "processed #{upload_operation.youtube_video_id}"			
		end
	end

	def self.generate_random_emails(domain,count)		
		1.upto(count.to_i) do 	
			use_point_separator = [true,false].sample

			first_name = Faker::Name.first_name
			last_name = Faker::Name.last_name
			chunks_separator = use_point_separator ? '.' : ''

			chunks = [first_name,last_name]
			puts "#{chunks.shuffle.join(chunks_separator).gsub(/['']/,'').downcase}@#{domain}"
		end
	end
	
	def self.generate_random_passwords(limit)
		1.upto(limit.to_i) do 				
			puts RandomPasswordGenerator.generate(rand(10..18),:skip_symbols => true)
		end
	end

	def self.test_token(email)
		google_account = GoogleAccount.where({email:email}).first
		is_api_accessible = nil
		if !google_account.nil?
			is_api_accessible = true
			begin
				google_account.fetch_access_token!
			rescue Signet::AuthorizationError
				is_api_accessible = false
				google_account.is_active = false
				google_account.google_status = 3												
			end
			google_account.updated_at = Time.now
			google_account.save
			puts "#{google_account.email} #{is_api_accessible}"			
		else
			puts "Google account not found"
		end
		is_api_accessible
	end

	module_function :import_popular_us_languages,								
		:upload_youtube_video_thumbnail,
		:get_random_case_tags,
		:save_to_tempfile,
		:import_case_types,
		:import_geo_info,
		:import_qualifiers,
		:import_tag_lines,
		:generate_video_params,
		:generate_case_type_thumbnail,
		:import_youtube_video_categories,
		:import_tags,
		:import_refresh_tokens,		
		:create_youtube_videos

	private

	def self.get_case_tags(row)
		tags = []
		(2 .. 5).each do |i|		
			row[i].split(',').each {|chunk| tags.push(Utils::titleize(chunk.strip)) if chunk} if row[i]
		end
		
		return tags.uniq
	end
end