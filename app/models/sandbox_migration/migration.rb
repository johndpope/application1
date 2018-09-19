module SandboxMigration
	module Migration
		def self.migrate
			puts "migration started"
			ActiveRecord::Base.transaction do
				migrate_categories

				puts "Clients migration started"
				SandboxMigration::Client.all.each do |c|
					::Client.where(name: c.name).first_or_create do |client|
						client.name = c.name
					end
				end

				SandboxMigration::Client.all.each do |c|
					puts "processing #{c.name}"
					broadcaster_client = ::Client.find_by_name(c.name)
					broadcaster_sandbox_client = Sandbox::Client.where(client_id: broadcaster_client.id).first_or_create do |sandbox_client|
						sandbox_client.uuid = c.uuid
						sandbox_client.description = c.description
						sandbox_client.client_category = Sandbox::ClientCategory.find_by_name(c.category.name)
						sandbox_client.is_active = true

						unless c.logo.path.blank?
							begin
								f = open(File.join(sandbox_path, c.logo.url(:original, timestamp: false)))
								sandbox_client.logo = f
								f.close
							end
						end

						unless c.background_image.path.blank?
							begin
								f = open(File.join(sandbox_path, c.background_image.url(:original, timestamp: false)))
								sandbox_client.background_image = f
								f.close
							end
						end

						unless c.subject_image.path.blank?
							begin
								f = open(File.join(sandbox_path, c.subject_image.url(:original, timestamp: false)))
								sandbox_client.subject_image = f
								f.close
							end
						end
					end

					migrate_video_sets(broadcaster_sandbox_client, c)
					migrate_campaign_video_sets(broadcaster_sandbox_client, c)
					migrate_locality_details
				end
				puts "Clients migration finished"
			end
			puts "Migration finished"
		end

		def self.migrate_categories
			puts "Categories Migration started"
			SandboxMigration::Category.all.each do |c|
				puts "processing #{c.name}"
				Sandbox::ClientCategory.where(name: c.name).first_or_create
			end
			puts "Categories Migration finished"
		end

		def self.migrate_video_sets(broadcaster_sandbox_client, sandbox_client)
			sandbox_client.video_sets.each do |sandbox_video_set|
				puts "processing video set #{sandbox_video_set.title}"
				broadcaster_sandbox_video_set = Sandbox::VideoSet.where(sandbox_client_id: broadcaster_sandbox_client.id, title: sandbox_video_set.title).first_or_create do |video_set|
					video_set.order_nr = sandbox_video_set.order_nr
					video_set.is_active = true

					unless sandbox_video_set.thumb.blank?
						begin
							f = open(File.join(sandbox_path, sandbox_video_set.thumb.url(:original, timestamp: false)))
							video_set.thumb = f
							f.close
						end
					end

					unless sandbox_video_set.blended_sample.blank?
						begin
							f = open(File.join(sandbox_path, sandbox_video_set.blended_sample.url(:original, timestamp: false)))
							video_set.blended_sample = f
							f.close
						end
					end
				end

				migrate_videos(broadcaster_sandbox_video_set, sandbox_video_set)
			end
		end

		def self.migrate_videos(broadcaster_sandbox_video_set, sandbox_video_set)
			%w(video transition).each do |vid|
				sandbox_video_set.send(vid.pluralize).each do |v|
					puts "processing video #{v.title}"
					Sandbox::Video.where(sandbox_video_set_id: broadcaster_sandbox_video_set.id, title: v.title).first_or_create do |video|
						video.description = v.description
						video.video_type = v.video_type
						video.locality_id = v.locality_id
						video.is_active = v.is_active == true || v.is_active == nil ? true : false

						unless v.thumb.blank?
							begin
								f = open(File.join(sandbox_path, v.thumb.url(:original, timestamp: false)))
								video.thumb = f
								f.close
							end
						end

						unless v.video.blank?
							begin
								f = open(File.join(sandbox_path, v.video.url(:original, timestamp: false)))
								video.video = f
								f.close
							end
						end
					end
				end
			end
		end

		def self.migrate_campaign_video_sets(broadcaster_sandbox_client, sandbox_client)
			puts "Importing campaign video sets ..."
			sandbox_client.campaign_video_sets.all.each do |sandbox_campaign_video_set|
				broadcaster_video_campaign = Sandbox::VideoCampaign.where(sandbox_client_id: broadcaster_sandbox_client.id, title: sandbox_campaign_video_set.name).first_or_create do |bvc|
					puts "Importing #{bvc.title}"
					bvc.is_active = true
					bvc.order_nr = sandbox_campaign_video_set.order_nr
				end
				migrate_campaign_videos(broadcaster_video_campaign, sandbox_campaign_video_set)
			end
		end

		def self.migrate_campaign_videos(broadcaster_video_campaign, sandbox_campaign_video_set)
			puts "Importing campaign videos from #{broadcaster_video_campaign.title}"
			sandbox_campaign_video_set.campaign_videos.all.each do |sandbox_campaign_video|
				puts "Importing #{sandbox_campaign_video.title}"
				Sandbox::VideoCampaignVideoStage.where(video_campaign_id: broadcaster_video_campaign.id, locality_id: sandbox_campaign_video.locality_id, title: sandbox_campaign_video.title).first_or_create do |vcvs|
					vcvs.month_nr = sandbox_campaign_video.month_nr
					vcvs.is_active = true
					vcvs.description = sandbox_campaign_video.description
					vcvs.tags = sandbox_campaign_video.tags
					vcvs.likes = sandbox_campaign_video.likes
					vcvs.dislikes = sandbox_campaign_video.dislikes
					vcvs.shares = sandbox_campaign_video.shares
					vcvs.comments = sandbox_campaign_video.comments
					vcvs.views = sandbox_campaign_video.views
					vcvs.position = sandbox_campaign_video.position

					unless sandbox_campaign_video.thumbnail.blank?
						begin
							f = open(File.join(sandbox_path, sandbox_campaign_video.thumbnail.url(:original, timestamp: false)))
							vcvs.thumbnail = f
							f.close
						end
					end
				end
			end
		end

		def self.migrate_locality_details
			puts "Importing locality details ..."
			SandboxMigration::LocalityDetails.all.each do |sandbox_locality_details|
				Sandbox::LocalityDetails.where(locality_id: sandbox_locality_details.locality_id).first_or_create do |locality_details|
					unless sandbox_locality_details.default_background_image.blank?
						begin
							f = open(File.join(sandbox_path, sandbox_locality_details.default_background_image.url(:original, timestamp: false)))
							locality_details.default_background_image = f
							f.close
						end
					end

					unless sandbox_locality_details.active_background_image.blank?
						begin
							f = open(File.join(sandbox_path, sandbox_locality_details.active_background_image.url(:original, timestamp: false)))
							locality_details.active_background_image = f
							f.close
						end
					end
				end
			end
		end

		def self.fix_video_ids
			ActiveRecord::Base.transaction do
				SandboxMigration::VideoSet.all.each do |svs|
					if bsvs = Sandbox::VideoSet.find_by_title(svs.title)
						puts "processing video set #{svs.title} ..."
						%w(videos transitions).each do |v|
							svs.send(v).each do |sv|
								if bsv = Sandbox::Video.where(sandbox_video_set_id: bsvs.id, title: sv.title).first
									puts "changing locality for video #{bsv.title} to #{sv.try(:locality).try(:name)}"
									bsv.locality_id = sv.locality_id
									bsv.save!
								end
							end
						end
					end
				end

				Sandbox::Video.all.each do |v|
					unless v.title.blank?
						potential_loc_id_part = v.title.split(' ').last.to_s.downcase
						if potential_loc_id_part.include? 'locid'
							locid = potential_loc_id_part.gsub('locid','').to_i
							puts "changing locality for video #{v.title} to #{Geobase::Locality.find_by_id(locid).try(:name)}"
							v.locality_id = locid
							v.save!
						end
					end
				end
			end
		end

		def self.sandbox_path
			if Rails.env.development?
				'http://localhost:3001'
			elsif Rails.env.production?
				'http://sandbox.echovideoblender.net'
			end
		end
	end
end
