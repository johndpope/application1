module YoutubeService
  YOUTUBE_STATISTICS_ENABLED = false
  YT_PUSHBULLET_RECEIVERS = "zavorotnii@gmail.com,black3mamba@gmail.com"
  class << self
    def spin_paragraphs(item)
      youtube_setup = item.is_a?(YoutubeSetup) ? item : YoutubeSetup.find(item)
      %w(business personal).each do |type|
        %w(channel video).each do |target|
          accessor = "#{type}_#{target}_description_paragraphs"
          youtube_setup.send(accessor).where(
            "body IS NOT NULL AND body <> '' AND (spintax IS NULL OR spun_at < updated_at OR spun_at IS NULL)"
          ).each do |p|
            spintax = WordAI.regular(s: p.body, quality: 'Readable', protected: youtube_setup.protected_words)
            p.update_attributes(spintax: spintax, spun_at: Time.now)
          end
        end
      end
    end

    def start_channels_process(email_accounts_setup_id)
      if Rails.env.production?
        email_accounts_setup = EmailAccountsSetup.where("id = ? ", email_accounts_setup_id).first
        if email_accounts_setup.present? && email_accounts_setup.youtube_setup.present?
          email_accounts = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("email_accounts_setup_id = ?", email_accounts_setup.id)
          youtube_setup = email_accounts_setup.youtube_setup
          contract = email_accounts_setup.contract
					client = email_accounts_setup.client
					industry = client.industry
          ##spin paragraphs
          # spin_paragraphs(youtube_setup)
					##spin client descriptions
					# client.wordings.each { |wording| wording.generate_spintax(client.protected_words.to_s)}
					##spin product descriptions
					# product.wordings.each { |wording| wording.generate_spintax(product.protected_words.to_s)}
					##spin industry descriptions
					# industry.wordings.each { |wording| wording.generate_spintax(industry.name.to_s.split(",").collect(&:strip).uniq.join(","))} if industry.present?

          business_channel_descriptors = youtube_setup.business_channel_descriptor
          business_channel_entities = youtube_setup.business_channel_entity
          business_channel_subjects = youtube_setup.business_channel_subject

					google_accounts = GoogleAccount.includes(:email_account)
						.joins(:youtube_channels)
						.where("email_accounts.id in (?)", email_accounts.map(&:id))
					accounts_pool = []
		      google_accounts.each do |ga|
		        accounts_pool << ga.email_account if ga.youtube_channels.size == 1
		      end
          accounts_pool.each do |ea|

            #business channels
            email_accounts_setup.channels_per_account.times do
              #title
              business_channel = YoutubeChannel.new
              #assign google account
              business_channel.google_account = ea.email_item
              #channel_type
              business_channel.channel_type = :business
              #category random()
              business_channel.category = YoutubeChannel.category.find_value(YoutubeChannel.category.values.sample).value
              #business_inquiries_email
              business_channel.business_inquiries_email = youtube_setup.business_inquiries_email

              business_channel_title_pattern_arr = youtube_setup.business_channel_title_patterns.shuffle.first.split(",")

              business_channel_descriptors_sample = business_channel_title_pattern_arr.include?("A") ? business_channel_descriptors.to_a.sample.try(:camelize) : nil
							business_channel_entities_sample = business_channel_title_pattern_arr.include?("B") ? business_channel_entities.to_a.sample.try(:camelize) : nil
							business_channel_subjects_sample =  business_channel_title_pattern_arr.include?("D") ? business_channel_subjects.to_a.sample.try(:camelize) : nil

							channel_name_delimiter_sample = YoutubeChannel::CHANNEL_NAME_DELIMITERS.sample
              channel_name_limit = Setting.get_value_by_name("YoutubeChannel::CHANNEL_NAME_LIMIT").to_i

              locality_component = if ea.locality.present?
                locality_name_with_full_region_name = ea.locality.name_with_parent_region("@", "full")
                locality_name_with_abbr_region_name = ea.locality.name_with_parent_region(" ", "abbr")
                if [business_channel_descriptors_sample, business_channel_entities_sample, locality_name_with_full_region_name, business_channel_subjects_sample].compact.join(channel_name_delimiter_sample).strip.size <= channel_name_limit && locality_name_with_full_region_name.split("@").uniq.size == 2
                  [locality_name_with_full_region_name.split("@").join(" "), locality_name_with_abbr_region_name].shuffle.first
                elsif [business_channel_descriptors_sample, business_channel_entities_sample, locality_name_with_abbr_region_name, business_channel_subjects_sample].compact.join(channel_name_delimiter_sample).strip.size <= channel_name_limit
                  [locality_name_with_abbr_region_name]
                else
                  ea.locality.name_with_parent_region(" ", "")
                end
              else
                ea.region.name
              end
              channel_name = [business_channel_descriptors_sample, business_channel_entities_sample, locality_component, business_channel_subjects_sample].compact
              if channel_name.join(channel_name_delimiter_sample).strip.size > channel_name_limit
                channel_name = [business_channel_entities_sample, locality_component, business_channel_subjects_sample].compact
                if channel_name.join(channel_name_delimiter_sample).strip.size > channel_name_limit
                  channel_name = [business_channel_entities_sample, locality_component].compact
                end
              end
              business_channel.youtube_channel_name = youtube_setup.business_channel_title_components_shuffle ? channel_name.shuffle.join(channel_name_delimiter_sample).strip.first(channel_name_limit) : channel_name.join(channel_name_delimiter_sample).strip.first(channel_name_limit)

              #keywords
              business_channel_keywords = []
              youtube_channel_tags_limit = Setting.get_value_by_name("YoutubeChannel::TAGS_LIMIT").to_i
              youtube_channel_tags_chars_limit = Setting.get_value_by_name("YoutubeChannel::TAGS_CHARS_LIMIT").to_i
              youtube_tag_size_limit = Setting.get_value_by_name("YoutubeVideo::TAG_SIZE_LIMIT").to_i
              tag_groups_size = 4
              tag_groups_size -= 1 unless industry.tag_list.present?
              tag_groups_size -= 1 unless youtube_setup.other_business_channel_tag_list.present?
              business_channel_keywords << client.tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size)
              business_channel_keywords << industry.tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size) if industry.tag_list.present?
              business_channel_keywords << youtube_setup.other_business_channel_tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size) if youtube_setup.other_business_channel_tag_list.present?
              # business_channel_tag_groups = youtube_setup.business_channel_tags_paragraphs
							# if business_channel_tag_groups.size > 0
	            #   business_channel_tag_groups.each do |bctg|
	            #     business_channel_keywords << bctg.body.split(",").sample(Setting.get_value_by_name("YoutubeChannel::TAGS_LIMIT").to_i/(business_channel_tag_groups.size + 1))
	            #   end
							# end
              geo_tags = []
              geo_tags << ea.try(:locality).try(:name) if ea.try(:locality).try(:name).present?
              geo_tags << ea.try(:region).try(:name) if ea.try(:region).try(:name).present?
              geo_tags << ea.try(:locality).try(:primary_region).try(:name) if ea.try(:locality).try(:primary_region).try(:name).present?
							geo_tags << ea.try(:locality).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:nicknames).present?
							geo_tags << ea.try(:region).try(:nicknames).try(:split, "<sep/>") if ea.try(:region).try(:nicknames).present?
							geo_tags << ea.try(:locality).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:code).present?
							geo_tags << ea.try(:locality).try(:primary_region).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:code).present?
							geo_tags << ea.try(:locality).try(:primary_region).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:nicknames).present?
							geo_tags << ea.try(:region).try(:code).try(:split, "<sep/>") if ea.try(:region).try(:code).present?
              geo_tags << ea.try(:locality).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:landmarks).present?
              geo_tags << ea.try(:region).try(:landmarks).try(:pluck, :name) if ea.try(:region).try(:landmarks).present?
              geo_tags << ea.try(:locality).try(:primary_region).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:primary_region).try(:landmarks).present?

              geo_tags.flatten!
              geo_tags.map(&:strip!)
              locality_name_tag = geo_tags.first
              geo_tags.reject!{|t| t.size >= youtube_tag_size_limit}
              geo_tags.shuffle!

              business_channel_keywords << geo_tags.sample(youtube_channel_tags_limit - business_channel_keywords.flatten.size)
              business_channel_keywords.flatten!
              business_channel_keywords = business_channel_keywords.compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.shuffle
              #force to add name of the locality as tag
              business_channel_keywords.insert(0, locality_name_tag) if locality_name_tag.present?
              keywords = business_channel_keywords.uniq{|e| e.mb_chars.downcase.to_s}.join(",")
              keywords = keywords.split(",").reject{|t| t.size >= youtube_tag_size_limit}.join("\" \"").truncate(youtube_channel_tags_chars_limit - 2, separator: /\s/).split("\" \"").join(",")
              if keywords.include?("...")
                keywords_array = keywords.split(",")
                keywords_array.pop
                keywords = keywords_array.join(",")
              end
              business_channel.keywords = keywords.split(",").reject{|t| t.size >= youtube_tag_size_limit}.shuffle.join(",")

              #channel_links
              business_channel_links_array = {links: []}
              business_channel_links = youtube_setup.business_channel_art_references.shuffle
              business_channel_links.each do |bcl|
                business_channel_link = {}
                business_channel_link["name"] = bcl.description
                business_channel_link["url"] = bcl.url
                business_channel_links_array[:links] << business_channel_link
              end
              business_channel.channel_links = business_channel_links_array.to_json

              #description
							business_channel.description = ""
							business_channel_description_array = []
							# business_channel_description_array << client.description_wording("short_description").try(:spintax).try(:unspin)
							# business_channel_description_array << product.description_wording_with_parent("short_description").try(:spintax).try(:unspin)
							##business_channel_description_array << industry.description_wording("short_description").try(:spintax).try(:unspin) if industry.present?
              business_channel_description_array << client.description_wording("short_description").try(:source)
              business_channel_description_array << youtube_setup.description_wording("short_description").try(:source)
              business_channel_description_array << industry.description_wording("short_description").try(:source) if industry.present?

							location_type = ""
							location_id = if ea.locality.present?
								location_type = ea.try(:locality).try(:class).try(:name)
                ea.locality.id
              else
								location_type = ea.try(:region).try(:class).try(:name)
                ea.try(:region).try(:id)
              end
							location_wording = Wording.where("resource_id = ? AND resource_type= ? AND name = ?", location_id, location_type, 'short_description').order("random()").first
              if !location_wording.present? && ea.locality.present? && ea.locality.neighbors.present?
                location_wording = Wording.where("resource_id in (?) AND resource_type= ? AND name = ?", ea.locality.neighbors.map(&:id), location_type, 'short_description').order("random()").first
              end
							if location_wording.present?
								# location_wording.generate_spintax(location_wording.resource.try(:protected_words).to_s)
								# business_channel_description_array << location_wording.spintax.unspin
                business_channel_description_array << location_wording.source
							end
              business_channel_description_array.shuffle!
              ##business_channel_description_array << youtube_setup.business_channel_description(spin: true)

							business_channel_description_array = business_channel_description_array.reject(&:blank?)
							if business_channel_description_array.present?
                channel_description_limit = Setting.get_value_by_name("YoutubeChannel::CHANNEL_DESCRIPTION_LIMIT").to_i
                total_characters_limit = channel_description_limit
                business_channel_description_array_size = business_channel_description_array.size
                paragraph_limit = total_characters_limit / business_channel_description_array_size
                business_channel_description_array.reverse!
                business_channel.description = business_channel_description_array.collect do |x|
                  s = x
                  init_sentences_count = Utils.smart_sentences_count(s)
                  sentences_count = init_sentences_count
                  while sentences_count > 0 && paragraph_limit < s.size do
                    sentences_count -= 1
                    s = Utils.smart_sentences_truncate(s, sentences_count)
                  end
                  s = Utils.smart_sentences_truncate(x, 1).truncate(paragraph_limit, separator: /\s/) if sentences_count == 0 && Utils.smart_sentences_truncate(x, 1).size > paragraph_limit
                  business_channel_description_array_size -= 1
                  total_characters_limit = total_characters_limit - s.size
                  paragraph_limit = total_characters_limit / business_channel_description_array_size if business_channel_description_array_size > 0
                  s
                end.reject(&:blank?).reverse.join(" ").strip.first(channel_description_limit)
							end

							business_channel.linked = false
							business_channel.is_active = false
							business_channel.is_verified_by_phone = false
							business_channel.filled = false
              business_channel.ready = false
              business_channel.save

              #channel icon
              if youtube_setup.use_youtube_channel_icon
                business_channel.generate_icon
              end

              #channel_art
              if youtube_setup.use_youtube_channel_art
                business_channel.generate_art
              end

              #generated associated website
              unless client.ignore_landing_pages
                contract.products.each do |product|
                  client_landing_page = ClientLandingPage.where(product_id: product.id, hosted: true, parked: true).order("random()").first
                  if client_landing_page.present?
                    AssociatedWebsite.create(client_landing_page_id: client_landing_page.id, youtube_channel_id: business_channel.id, ready: true, linked: true)
                  end
                end
              end
            end
            google_account_activity = ea.email_item.google_account_activity
            google_account_activity.linked = false
            google_account_activity.save
          end
          if accounts_pool.size > 0
            PusherService.push_message("Youtube channels for #{client.try(:name)} client were successfully created! Please review and approve content and put \"Ready\" checkmark.", "Youtube channels")
            # now = Time.now
            # ActiveRecord::Base.logger.info "Activities for business channels run time : #{now}"
            # start_job_response = %x(curl -X GET "#{Setting.get_value_by_name("EmailAccount::BOT_URL")}/add_activity_count.php?count=#{accounts_pool.size}")
            # ActiveRecord::Base.logger.info "#{start_job_response}"
          end
        end
      end
    end

		def start_videos_process(email_accounts_setup_id)
			if Rails.env.production?
				email_accounts_setup = EmailAccountsSetup.where("id = ? ", email_accounts_setup_id).first
				if email_accounts_setup.present? && email_accounts_setup.youtube_setup.present?
					email_accounts = EmailAccount.by_account_type(EmailAccount.account_type.find_value(:operational).value).where("email_accounts_setup_id = ?", email_accounts_setup.id)

					google_accounts_ids = GoogleAccount.includes(:email_account)
						.joins(:youtube_channels)
						.where("email_accounts.id in (?) AND youtube_channels.channel_type = ?", email_accounts.map(&:id), YoutubeChannel.channel_type.find_value(:business).value).pluck(:id)
					youtube_business_channels = YoutubeChannel.where("google_account_id in (?) AND channel_type = ?", google_accounts_ids, YoutubeChannel.channel_type.find_value(:business).value)
					youtube_business_channels.each do |ybc|
						#create video content
						#ybc.generate_video
					end
					if youtube_business_channels.size > 0
						# now = Time.now
						# ActiveRecord::Base.logger.info "Activities for business videos run time : #{now}"
						# start_job_response = %x(curl -X GET "#{Setting.get_value_by_name("EmailAccount::BOT_URL")}/add_activity_count.php?count=#{youtube_business_channels.size}")
						# ActiveRecord::Base.logger.info "#{start_job_response}"
					end
				end
			end
		end

    def regenerate_youtube_video_content(youtube_video, exclude_fields_list = ["title", "thumbnail"])
      # ["thumbnail", "title", "tags", "description"]
      #TODO: add other fields
      youtube_video_tag_size_limit = Setting.get_value_by_name("YoutubeVideo::TAG_SIZE_LIMIT").to_i
      youtube_channel = youtube_video.youtube_channel
      ea = youtube_video.youtube_channel.google_account.email_account
  		email_accounts_setup = ea.email_accounts_setup
  		youtube_setup = email_accounts_setup.try(:youtube_setup)
      client = email_accounts_setup.client
      blended_video = youtube_video.blended_video
      source_video = blended_video.try(:source_video)
      product = source_video.try(:product)
      donor_client = product.try(:parent).try(:client)
      #do not permit create youtube video without associated website to channel
      has_associated_website = client.ignore_landing_pages || ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", youtube_channel.id, product.id).present?

      if product.present? && email_accounts_setup.present? && youtube_setup.present? && has_associated_website
        client_landing_page = client.ignore_landing_pages ? nil : ClientLandingPage.joins("LEFT JOIN associated_websites ON associated_websites.client_landing_page_id = client_landing_pages.id").where("associated_websites.youtube_channel_id = ? AND associated_websites.ready = TRUE AND associated_websites.linked = TRUE AND client_landing_pages.product_id = ?", youtube_channel.id, product.id).order("random()").first
  			industry = client.industry
        donor_source_video = client.client_donor_source_videos.where(recipient_source_video_id: source_video.id).first.try(:source_video)

        business_video_descriptors = youtube_setup.business_video_descriptor
  			business_video_entities = youtube_setup.business_video_entity
  			business_video_subjects = youtube_setup.business_video_subject

        business_video_title_pattern_arr = youtube_setup.business_video_title_patterns.shuffle.first.split(",")

  			business_video_descriptors_sample = business_video_title_pattern_arr.include?("A") ? business_video_descriptors.to_a.sample.try(:camelize) : nil
  			business_video_entities_sample = business_video_title_pattern_arr.include?("B") ? business_video_entities.to_a.sample.try(:camelize) : nil

        business_video_industry_component = if industry.nickname.present? && industry.industry_title_components.to_a.present?
          industry_title_groups = [industry.nickname, industry.try(:industry_title_components).to_a.sample.try(:camelize)]
          industry_groups_hash = {
            industry_title_groups[0] => 70,
            industry_title_groups[1] => 30,
          }
          industry_pickup = Pickup.new(industry_groups_hash)
          industry_group = industry_pickup.pick
        else
          industry.nickname || industry.try(:industry_title_components).to_a.sample.try(:camelize)
        end

        business_video_industry_sample = business_video_title_pattern_arr.include?("G") ? business_video_industry_component : nil

        if business_video_title_pattern_arr.include?("G") && business_video_entities_sample.present? && business_video_industry_sample.present?
          business_video_entities_sample = [business_video_industry_sample, business_video_entities_sample].join(" ")
          business_video_industry_sample = nil
        end

        business_video_subjects_sample = business_video_title_pattern_arr.include?("D") ? business_video_subjects.to_a.sample.try(:camelize) : nil

        subject_video_title_components = source_video.try(:subject_title_components).to_a + donor_source_video.try(:subject_title_components).to_a
        business_video_subject_videos_sample = business_video_title_pattern_arr.include?("E") ? subject_video_title_components.sample.try(:camelize) : nil

        product_title_components = product.try(:subject_title_components).to_a + product.try(:parent).try(:subject_title_components).to_a
        business_video_products_sample = business_video_title_pattern_arr.include?("C") ? product_title_components.sample.try(:camelize) : nil

        brand_title_component_sample = business_video_title_pattern_arr.include?("H") ? donor_client.try(:nickname) : nil

        video_name_delimiter_sample = YoutubeVideo::VIDEO_NAME_DELIMITERS.sample
        video_name_limit = Setting.get_value_by_name("YoutubeVideo::VIDEO_NAME_LIMIT").to_i
        if !exclude_fields_list.include?("title")
          locality_component = if ea.locality.present?
            locality_name_with_full_region_name = ea.locality.name_with_parent_region("@", "full")
            locality_name_with_abbr_region_name = ea.locality.name_with_parent_region(" ", "abbr")
            if [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_full_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.join(video_name_delimiter_sample).strip.size <= video_name_limit && locality_name_with_full_region_name.split("@").uniq.size == 2
    				  [locality_name_with_full_region_name.split("@").join(" "), locality_name_with_abbr_region_name].shuffle.first
            elsif [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_abbr_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.shuffle.join(video_name_delimiter_sample).strip.size <= video_name_limit
              [locality_name_with_abbr_region_name, ea.locality.name_with_parent_region(" ", "")].shuffle.first
            else
              ea.locality.name_with_parent_region(" ", "")
            end
    			else
    				ea.region.name
    			end
          video_title = [business_video_descriptors_sample, brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
          if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
            video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
            if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
              video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample].compact
              if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subjects_sample].compact
                if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                  video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component].compact
                  if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                    video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, locality_component].compact
                    if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                      video_title = [brand_title_component_sample, business_video_entities_sample, locality_component].compact
                      if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                        video_title = [business_video_entities_sample, locality_component].compact
                      end
                    end
                  end
                end
              end
            end
          end
    			youtube_video.title = youtube_setup.business_video_title_components_shuffle ? video_title.shuffle.join(video_name_delimiter_sample).strip.first(video_name_limit) : video_title.join(video_name_delimiter_sample).strip.first(video_name_limit)
        end
        geo_tags = []
        geo_tags << ea.try(:locality).try(:name) if ea.try(:locality).try(:name).present?
        geo_tags << ea.try(:region).try(:name) if ea.try(:region).try(:name).present?
        geo_tags << ea.try(:locality).try(:primary_region).try(:name) if ea.try(:locality).try(:primary_region).try(:name).present?
  			geo_tags << ea.try(:locality).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:nicknames).present?
  			geo_tags << ea.try(:region).try(:nicknames).try(:split, "<sep/>") if ea.try(:region).try(:nicknames).present?
  			geo_tags << ea.try(:locality).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:code).present?
  			geo_tags << ea.try(:locality).try(:primary_region).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:code).present?
  			geo_tags << ea.try(:locality).try(:primary_region).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:nicknames).present?
  			geo_tags << ea.try(:region).try(:code).try(:split, "<sep/>") if ea.try(:region).try(:code).present?
        geo_tags << ea.try(:locality).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:landmarks).present?
        geo_tags << ea.try(:region).try(:landmarks).try(:pluck, :name) if ea.try(:region).try(:landmarks).present?
        geo_tags << ea.try(:locality).try(:primary_region).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:primary_region).try(:landmarks).present?

        geo_tags.flatten!
        geo_tags.map(&:strip!)
        locality_name_tag = geo_tags.first
        geo_tags.reject!{|t| t.size >= youtube_video_tag_size_limit}
        geo_tags.shuffle!

        if !exclude_fields_list.include?("tags")
          business_video_tags = []
          youtube_video_tags_limit = Setting.get_value_by_name("YoutubeVideo::TAGS_LIMIT").to_i
          youtube_video_tags_chars_limit = Setting.get_value_by_name("YoutubeVideo::TAGS_CHARS_LIMIT").to_i
          tag_groups_size = 7
          tag_groups_size -= 1 unless source_video.try(:tag_list).to_a.present?
          tag_groups_size -= 1 unless youtube_setup.other_business_video_tag_list.present?
          tag_groups_size -= 1 unless industry.tag_list.present?
          tag_groups_size -= 1 unless donor_client.try(:tag_list).present?
          each_tag_part_size = youtube_video_tags_limit / tag_groups_size
          business_video_tags << client.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size)
          business_video_tags << product.tag_list_with_parent.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size)
          business_video_tags << donor_client.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if donor_client.try(:tag_list).present?
          business_video_tags << industry.tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if industry.tag_list.present?
          business_video_tags << (source_video.try(:tag_list) + donor_source_video.try(:tag_list)).to_a.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if source_video.try(:tag_list).to_a.present? || donor_source_video.try(:tag_list).to_a.present?
          business_video_tags << youtube_setup.other_business_video_tag_list.reject{|t| t.size >= youtube_video_tag_size_limit}.sample(each_tag_part_size) if youtube_setup.other_business_video_tag_list.present?

          business_video_tags << geo_tags.sample(youtube_video_tags_limit - business_video_tags.flatten.size)
    			business_video_tags.flatten!
          business_video_tags = business_video_tags.compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.shuffle
          #force to add name of the locality as tag
          business_video_tags.insert(0, locality_name_tag) if locality_name_tag.present?
          keywords = business_video_tags.uniq{|e| e.mb_chars.downcase.to_s}.reject{|t| t.size >= youtube_video_tag_size_limit}.join(",")
          keywords = keywords.split(",").join("\" \"").truncate(youtube_video_tags_chars_limit - 2, separator: /\s/).split("\" \"").join(",")
          if keywords.include?("...")
            keywords_array = keywords.split(",")
            keywords_array.pop
            keywords = keywords_array.join(",")
          end
          youtube_video.tags = keywords.split(",").reject{|t| t.size >= youtube_video_tag_size_limit}.shuffle.join(",")
        end

        if !exclude_fields_list.include?("description")
          youtube_video.description = ""
    			business_video_description_array = []
    			# business_video_description_array << client.description_wording("long_description").try(:spintax).try(:unspin)
    			# business_video_description_array << product.description_wording_with_parent("long_description").try(:spintax).try(:unspin)
    			# business_video_description_array << industry.description_wording("long_description").try(:spintax).try(:unspin) if industry.present?
          business_video_description_array << client.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
          if donor_client.present?
            donor_client_description = donor_client.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
            business_video_description_array << donor_client_description if donor_client_description.present?
          end
          business_video_description_array << product.description_wording_with_parent(["long_description", "short_description"].shuffle.first).try(:source).try(:strip)
          business_video_description_array << industry.description_wording(["long_description", "short_description"].shuffle.first).try(:source).try(:strip) if industry.present?
          business_video_description_array << (source_video.try(:description_wording, "long_description").try(:source).try(:strip) || donor_source_video.try(:description_wording, "long_description").try(:source).try(:strip)) if source_video.try(:description_wording, "long_description").try(:source).present? || donor_source_video.try(:description_wording, "long_description").try(:source).present?
          business_video_description_array << youtube_setup.description_wording("long_description").try(:source).try(:strip)
          business_video_description_array << "\n" + TextChunk.where(chunk_type: 'client_landing_page_action').order('random()').first.value.try(:strip) + " " + client_landing_page.page_url + " .\n" if youtube_setup.use_landing_page_link_in_youtube_video_description && client_landing_page.present?
          if youtube_setup.social_links_in_youtube_video_description.to_i > 0
            parts = []
            parts << TextChunk.where(chunk_type: 'blog_action').order('random()').first.value.try(:strip) + " " + client.blog_url if client.blog_url.present?
            parts << TextChunk.where(chunk_type: 'google_plus_action').order('random()').first.value.try(:strip) + " " + client.google_plus_url if client.google_plus_url.present?
            parts << TextChunk.where(chunk_type: 'youtube_action').order('random()').first.value.try(:strip) + " " + client.youtube_url if client.youtube_url.present?
            parts << TextChunk.where(chunk_type: 'facebook_action').order('random()').first.value.try(:strip) + " " + client.facebook_url if client.facebook_url.present?
            parts << TextChunk.where(chunk_type: 'twitter_action').order('random()').first.value.try(:strip) + " " + client.twitter_url if client.twitter_url.present?
            parts << TextChunk.where(chunk_type: 'linkedin_action').order('random()').first.value.try(:strip) + " " + client.linkedin_url if client.linkedin_url.present?
            parts << TextChunk.where(chunk_type: 'instagram_action').order('random()').first.value.try(:strip) + " " + client.instagram_url if client.instagram_url.present?
            parts << TextChunk.where(chunk_type: 'pinterest_action').order('random()').first.value.try(:strip) + " " + client.pinterest_url if client.pinterest_url.present?
            parts.shuffle!
            parts = parts.first(youtube_setup.social_links_in_youtube_video_description.to_i)
            business_video_description_array << "\n" + parts.join(" .\n") + ". \n"
          end

    			location_type = ""
    			location_id = if ea.locality.present?
    				location_type = ea.try(:locality).try(:class).try(:name)
    				ea.locality.id
    			else
    				location_type = ea.try(:region).try(:class).try(:name)
    				ea.try(:region).try(:id)
    			end
    			location_wording = Wording.where("resource_id = ? AND resource_type= ? AND name = ?", location_id, location_type, 'long_description').order("random()").first
          if !location_wording.present? && ea.locality.present? && ea.locality.neighbors.present?
            location_wording = Wording.where("resource_id in (?) AND resource_type= ? AND name = ?", ea.locality.neighbors.map(&:id), location_type, 'long_description').order("random()").first
          end
    			if location_wording.present?
    				# location_wording.generate_spintax(location_wording.resource.try(:protected_words).to_s)
    				# business_video_description_array << location_wording.spintax.unspin
            business_video_description_array << location_wording.source.try(:strip)
    			end

    			#credits link
    			#TODO: Fix route path error occuring when option Rails.application.routes.default_url_options[:host] is on
    			#Temporary solution is to use Rails.configuration.routes_default_url_options[:host]
          credits_part = "\n" + [TextChunk.where(chunk_type: 'credits_action').order('random()').first.try(:value).to_s.try(:strip), "#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.public_credits_youtube_video_path(youtube_video)}"].join(' ') + " .\n"
          business_video_description_array = business_video_description_array.reject(&:blank?)
          business_video_description_array.shuffle!
          business_video_description_array.insert([0,1,2].shuffle.first, credits_part)
          # business_video_description_array << youtube_setup.business_video_description(spin: true)

          video_description_limit = Setting.get_value_by_name("YoutubeVideo::VIDEO_DESCRIPTION_LIMIT").to_i
    			if business_video_description_array.present?
            total_characters_limit = video_description_limit
            business_video_description_array_size = business_video_description_array.size
            paragraph_limit = total_characters_limit / business_video_description_array_size
            business_video_description_array.reverse!
            youtube_video.description = business_video_description_array.collect do |x|
              s = x
              init_sentences_count = Utils.smart_sentences_count(s)
              sentences_count = init_sentences_count
              while sentences_count > 0 && paragraph_limit < s.size do
                sentences_count -= 1
                s = Utils.smart_sentences_truncate(s, sentences_count)
              end
              s = Utils.smart_sentences_truncate(x, 1).truncate(paragraph_limit, separator: /\s/) if sentences_count == 0 && Utils.smart_sentences_truncate(x, 1).size > paragraph_limit
              business_video_description_array_size -= 1
              total_characters_limit = total_characters_limit - s.size
              paragraph_limit = total_characters_limit / business_video_description_array_size if business_video_description_array_size > 0

    					#Exception Encoding::CompatibilityError: incompatible character encodings: UTF-8 and ASCII-8BIT sometime raises.
    					#Temporary solution is to apply .force_encoding('UTF-8') for the spinned string
    					s.force_encoding('UTF-8')
            end.reject(&:blank?).reverse.join(" ").strip.first(video_description_limit)
    			end

          youtube_video.description = youtube_video.description.gsub("\n \n", "\n").gsub(/[\r\n]+/, "\n").gsub(/[\n\r]+/, "\n").gsub(/[\n]+/, "\n").strip.first(video_description_limit)

          #add keywords to the end of description
          # description_tags = []
          # description_tags << business_video_tags
          # # if business_video_tag_groups.size > 0
          # #   business_video_tag_groups.each do |bvtg|
          # #     description_tags << bvtg.body.split(",")
          # #   end
          # # end
          # description_tags << geo_tags
          # description_tags.flatten!
          # description_tags.map(&:strip!)
          # description_tags.uniq!
          #
          # if description_tags.present?
          #   keywords_bridge = TextChunk.where(chunk_type: "keywords_bridge").order("random()").first.try(:value)
          #   youtube_video.description = [youtube_video.description + "\n", keywords_bridge, description_tags.shuffle.join(", ")].reject(&:blank?).join(" ").truncate(video_description_limit, separator: /\s/, omission: "...")
          #   if youtube_video.description.include?("...") && youtube_video.description.include?(keywords_bridge)
          #     description_array = youtube_video.description.split(",")
          #     description_array.pop if description_array.size > 1
          #     youtube_video.description = description_array.join(",") + "."
          #   end
          # end
    			# youtube_video.description = youtube_video.description.first(video_description_limit)
          # youtube_video.description = youtube_video.description.first(youtube_video.description.size - 1) if youtube_video.description.last(2) == ".."
        end

        youtube_video.linked = false
        youtube_video.rotate_content_date = Time.now
        saved = youtube_video.save!

        if !exclude_fields_list.include?("thumbnail")
          Delayed::Job.enqueue Youtube::GenerateThumbnailForCreatedYoutubeVideoJob.new(youtube_video.id), queue: DelayedJobQueue::YOUTUBE_CREATE_VIDEO_THUMBNAIL_FOR_GENERATED_VIDEO, priority: DelayedJobPriority::MEDIUM
        end
        saved
      end
    end

		def regenerate_youtube_business_channel_content(business_channel, ready, exclude_fields_list = ["name"])
      #full list ["name", "business_inquiries_email", "keywords", "channel_links", "description", "channel_icon", "channel_art"]
			#if Rails.env.production?
				email_accounts_setup = business_channel.google_account.email_account.email_accounts_setup
				if email_accounts_setup.present? && email_accounts_setup.youtube_setup.present?
					ea = business_channel.google_account.email_account
					youtube_setup = email_accounts_setup.youtube_setup
					client = email_accounts_setup.client
					industry = client.industry
					##spin paragraphs
					# spin_paragraphs(youtube_setup)
					##spin client descriptions
					# client.wordings.each { |wording| wording.generate_spintax(client.protected_words.to_s)}
					##spin product descriptions
					# product.wordings.each { |wording| wording.generate_spintax(product.protected_words.to_s)}
					##spin industry descriptions
					# industry.wordings.each { |wording| wording.generate_spintax(industry.name.to_s.split(",").collect(&:strip).uniq.join(","))} if industry.present?

					if !exclude_fields_list.include?("name")
						business_channel_descriptors = youtube_setup.business_channel_descriptor
						business_channel_entities = youtube_setup.business_channel_entity
						business_channel_subjects = youtube_setup.business_channel_subject

            business_channel_title_pattern_arr = youtube_setup.business_channel_title_patterns.shuffle.first.split(",")

            business_channel_descriptors_sample = business_channel_title_pattern_arr.include?("A") ? business_channel_descriptors.to_a.sample.try(:camelize) : nil
            business_channel_entities_sample = business_channel_title_pattern_arr.include?("B") ? business_channel_entities.to_a.sample.try(:camelize) : nil
            business_channel_subjects_sample =  business_channel_title_pattern_arr.include?("D") ? business_channel_subjects.to_a.sample.try(:camelize) : nil

            channel_name_delimiter_sample = YoutubeChannel::CHANNEL_NAME_DELIMITERS.sample
            channel_name_limit = Setting.get_value_by_name("YoutubeChannel::CHANNEL_NAME_LIMIT").to_i

            locality_component = if ea.locality.present?
              locality_name_with_full_region_name = ea.locality.name_with_parent_region("@", "full")
              locality_name_with_abbr_region_name = ea.locality.name_with_parent_region(" ", "abbr")
              if [business_channel_descriptors_sample, business_channel_entities_sample, locality_name_with_full_region_name, business_channel_subjects_sample].compact.join(channel_name_delimiter_sample).strip.size <= channel_name_limit && locality_name_with_full_region_name.split("@").uniq.size == 2
                [locality_name_with_full_region_name.split("@").join(" "), locality_name_with_abbr_region_name].shuffle.first
              elsif [business_channel_descriptors_sample, business_channel_entities_sample, locality_name_with_abbr_region_name, business_channel_subjects_sample].compact.join(channel_name_delimiter_sample).strip.size <= channel_name_limit
                locality_name_with_abbr_region_name
              else
                ea.locality.name_with_parent_region(" ", "")
              end
            else
              ea.region.name
            end
            channel_name = [business_channel_descriptors_sample, business_channel_entities_sample, locality_component, business_channel_subjects_sample].compact
            if channel_name.join(channel_name_delimiter_sample).strip.size > channel_name_limit
              channel_name = [business_channel_entities_sample, locality_component, business_channel_subjects_sample]
              if channel_name.join(channel_name_delimiter_sample).strip.size > channel_name_limit
                channel_name = [business_channel_entities_sample, locality_component]
              end
            end
            business_channel.youtube_channel_name = youtube_setup.business_channel_title_components_shuffle ? channel_name.shuffle.join(channel_name_delimiter_sample).strip.first(channel_name_limit) : channel_name.join(channel_name_delimiter_sample).strip.first(channel_name_limit)
					end
					#business_inquiries_email
					if !exclude_fields_list.include?("business_inquiries_email")
						business_channel.business_inquiries_email = youtube_setup.business_inquiries_email
					end
					#keywords
					if !exclude_fields_list.include?("keywords")
						business_channel_keywords = []
            youtube_channel_tags_limit = Setting.get_value_by_name("YoutubeChannel::TAGS_LIMIT").to_i
            youtube_channel_tags_chars_limit = Setting.get_value_by_name("YoutubeChannel::TAGS_CHARS_LIMIT").to_i
            youtube_tag_size_limit = Setting.get_value_by_name("YoutubeVideo::TAG_SIZE_LIMIT").to_i
            tag_groups_size = 4
            tag_groups_size -= 1 unless industry.tag_list.present?
            tag_groups_size -= 1 unless youtube_setup.other_business_channel_tag_list.present?
            business_channel_keywords << client.tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size)
            business_channel_keywords << industry.tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size) if industry.tag_list.present?
            business_channel_keywords << youtube_setup.other_business_channel_tag_list.reject{|t| t.size >= youtube_tag_size_limit}.sample(youtube_channel_tags_limit/tag_groups_size) if youtube_setup.other_business_channel_tag_list.present?
						# business_channel_tag_groups = youtube_setup.business_channel_tags_paragraphs
						# if business_channel_tag_groups.size > 0
						# 	business_channel_tag_groups.each do |bctg|
						# 		business_channel_keywords << bctg.body.split(",").sample(Setting.get_value_by_name("YoutubeChannel::TAGS_LIMIT").to_i/business_channel_tag_groups.size)
						# 	end
						# end
            #keywords

            geo_tags = []
            geo_tags << ea.try(:locality).try(:name) if ea.try(:locality).try(:name).present?
            geo_tags << ea.try(:region).try(:name) if ea.try(:region).try(:name).present?
            geo_tags << ea.try(:locality).try(:primary_region).try(:name) if ea.try(:locality).try(:primary_region).try(:name).present?
            geo_tags << ea.try(:locality).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:nicknames).present?
            geo_tags << ea.try(:region).try(:nicknames).try(:split, "<sep/>") if ea.try(:region).try(:nicknames).present?
            geo_tags << ea.try(:locality).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:code).present?
            geo_tags << ea.try(:locality).try(:primary_region).try(:code).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:code).present?
            geo_tags << ea.try(:locality).try(:primary_region).try(:nicknames).try(:split, "<sep/>") if ea.try(:locality).try(:primary_region).try(:nicknames).present?
            geo_tags << ea.try(:region).try(:code).try(:split, "<sep/>") if ea.try(:region).try(:code).present?
            geo_tags << ea.try(:locality).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:landmarks).present?
            geo_tags << ea.try(:region).try(:landmarks).try(:pluck, :name) if ea.try(:region).try(:landmarks).present?
            geo_tags << ea.try(:locality).try(:primary_region).try(:landmarks).try(:pluck, :name) if ea.try(:locality).try(:primary_region).try(:landmarks).present?

            geo_tags.flatten!
            geo_tags.map(&:strip!)

            locality_name_tag = geo_tags.first
            geo_tags.reject!{|t| t.size >= youtube_tag_size_limit}
            geo_tags.shuffle!

            business_channel_keywords << geo_tags.sample(youtube_channel_tags_limit - business_channel_keywords.flatten.size)
            business_channel_keywords.flatten!
            business_channel_keywords = business_channel_keywords.compact.map(&:strip).uniq{|e| e.mb_chars.downcase.to_s}.shuffle
            #force to add name of the locality as tag
            business_channel_keywords.insert(0, locality_name_tag) if locality_name_tag.present?
            keywords = business_channel_keywords.uniq{|e| e.mb_chars.downcase.to_s}.join(",")
            keywords = keywords.split(",").reject{|t| t.size >= youtube_tag_size_limit}.join("\" \"").truncate(youtube_channel_tags_chars_limit - 2, separator: /\s/).split("\" \"").join(",")
            if keywords.include?("...")
              keywords_array = keywords.split(",")
              keywords_array.pop
              keywords = keywords_array.join(",")
            end
            business_channel.keywords = keywords.split(",").reject{|t| t.size >= youtube_tag_size_limit}.shuffle.join(",")
					end
					#channel_links
					if !exclude_fields_list.include?("channel_links")
						business_channel_links_array = {links: []}
						business_channel_links = youtube_setup.business_channel_art_references.shuffle
						business_channel_links.each do |bcl|
							business_channel_link = {}
							business_channel_link["name"] = bcl.description
							business_channel_link["url"] = bcl.url
							business_channel_links_array[:links] << business_channel_link
						end
						business_channel.channel_links = business_channel_links_array.to_json
					end

					#description
					if !exclude_fields_list.include?("description")
						business_channel.description = ""
						business_channel_description_array = []
						# business_channel_description_array << client.description_wording("short_description").try(:spintax).try(:unspin)
						# business_channel_description_array << product.description_wording_with_parent("short_description").try(:spintax).try(:unspin)
						##business_channel_description_array << industry.description_wording("short_description").try(:spintax).try(:unspin) if industry.present?
            business_channel_description_array << client.description_wording("short_description").try(:source)
            business_channel_description_array << youtube_setup.description_wording("short_description").try(:source)
            business_channel_description_array << industry.description_wording("short_description").try(:source) if industry.present?

						location_type = ""
						location_id = if ea.locality.present?
							location_type = ea.try(:locality).try(:class).try(:name)
							ea.locality.id
						else
							location_type = ea.try(:region).try(:class).try(:name)
							ea.try(:region).try(:id)
						end
						location_wording = Wording.where("resource_id = ? AND resource_type= ? AND name = ?", location_id, location_type, 'short_description').order("random()").first
            if !location_wording.present? && ea.locality.present? && ea.locality.neighbors.present?
              location_wording = Wording.where("resource_id in (?) AND resource_type= ? AND name = ?", ea.locality.neighbors.map(&:id), location_type, 'short_description').order("random()").first
            end
						if location_wording.present?
							# location_wording.generate_spintax(location_wording.resource.try(:protected_words).to_s)
							# business_channel_description_array << location_wording.spintax.unspin
              business_channel_description_array << location_wording.source
						end
            business_channel_description_array.shuffle!
            ##business_channel_description_array << youtube_setup.business_channel_description(spin: true)

						business_channel_description_array = business_channel_description_array.reject(&:blank?)
						if business_channel_description_array.present?
              channel_description_limit = Setting.get_value_by_name("YoutubeChannel::CHANNEL_DESCRIPTION_LIMIT").to_i
              total_characters_limit = channel_description_limit
              business_channel_description_array_size = business_channel_description_array.size
              paragraph_limit = total_characters_limit / business_channel_description_array_size
              business_channel_description_array.reverse!
              business_channel.description = business_channel_description_array.collect do |x|
                s = x
                init_sentences_count = Utils.smart_sentences_count(s)
                sentences_count = init_sentences_count
                while sentences_count > 0 && paragraph_limit < s.size do
                  sentences_count -= 1
                  s = Utils.smart_sentences_truncate(s, sentences_count)
                end
                s = Utils.smart_sentences_truncate(x, 1).truncate(paragraph_limit, separator: /\s/) if sentences_count == 0 && Utils.smart_sentences_truncate(x, 1).size > paragraph_limit
                business_channel_description_array_size -= 1
                total_characters_limit = total_characters_limit - s.size
                paragraph_limit = total_characters_limit / business_channel_description_array_size if business_channel_description_array_size > 0
                s
              end.reject(&:blank?).reverse.join(" ").strip.first(channel_description_limit)
						end
					end

					business_channel.filled = false
					business_channel.ready = ready
					business_channel.save

					#channel icon
					if youtube_setup.use_youtube_channel_icon && !exclude_fields_list.include?("channel_icon")
						business_channel.generate_icon
					end

					#channel_art
					if youtube_setup.use_youtube_channel_art && !exclude_fields_list.include?("channel_art")
						business_channel.generate_art
					end
				end
			#end
		end

    def grab_channel_statistics(youtube_channel, p_addr, p_port, api_key, update_last = false)
      unless p_addr.present?
        system_accounts = EmailAccount.joins('LEFT OUTER JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all("true").by_is_active("true").by_account_type(EmailAccount.account_type.find_value(:system).value.to_s).where("google_accounts.youtube_data_api_key IS NOT NULL AND google_accounts.youtube_data_api_key <> '' AND ip_addresses.address_target = ?", IpAddress.address_target.find_value("free_proxy").value)
        random_system_account = system_accounts.shuffle.first
        p_addr = random_system_account.ip_address.address
        p_port = random_system_account.ip_address.port
        api_key = random_system_account.email_item.youtube_data_api_key
      end
      tries ||= 5
      last_stat = YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeChannel'", youtube_channel.id).order(created_at: :desc).first
      begin
        channel_stat = Yt::Channel.new(id: youtube_channel.youtube_channel_id, proxy_address: p_addr, proxy_port: p_port, api_key: api_key)
        videos_titles = []
        channel_stat.videos.each {|v| videos_titles << v.title}
        attr_hash = {view_count: channel_stat.view_count, comment_count: channel_stat.comment_count, video_count: channel_stat.video_count, subscriber_count: channel_stat.subscriber_count, duplicate_videos: videos_titles.uniq.size != videos_titles.size, public: channel_stat.public?, unlisted: channel_stat.unlisted?, private: channel_stat.private?, grab_succeded: true, current: true}
        YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeChannel' AND current = TRUE", youtube_channel.id).update_all(current: false)
        if update_last
          if last_stat.present?
            last_stat.reload
            last_stat.update_attributes(attr_hash)
          else
            youtube_channel.yt_statistics << YtStatistic.create(attr_hash)
          end
        else
          youtube_channel.yt_statistics << YtStatistic.create(attr_hash)
        end
      rescue
        sleep 10
        unless (tries -= 1).zero?
          retry
        else
          curl_response = %x(curl -x #{p_addr}:#{p_port} -X GET #{youtube_channel.url})
          unescaped_response = CGI.unescapeHTML(curl_response)
          html = Nokogiri::HTML.parse(curl_response)
          error_type = YtStatistic.error_type.find_value("Other").value
          YtStatistic::ERROR_CHANNEL_TYPES.keys.each do |k|
            if unescaped_response.include?(k)
              error_type = YtStatistic::ERROR_CHANNEL_TYPES[k]
              break
            end
          end
          if (html.css('.yt-alert-message').try(:text).present? && !html.css('.yt-alert-message').try(:text).to_s.include?("We've been hard at work on the new YouTube, and it's better than ever. Try it now")) || [8,9,10,12].include?(error_type)
            youtube_channel.blocked = true
            youtube_channel.save(validate: false)
            BotServer.kill_all_zenno
            BroadcasterMailer.new_blocked_youtube_channel(youtube_channel.id)
            Utils.pushbullet_broadcast("New blocked youtube channel!", "Please check new blocked youtube channel #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.youtube_channels_path(id: youtube_channel.id)}")
          end
          if error_type == YtStatistic.error_type.find_value("Other").value && youtube_channel.try(:google_account).try(:email_account).try(:is_active)
            Utils.pushbullet_broadcast("Check youtube channel!", "Please check youtube channel with error type: 'Other' #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.youtube_channels_path(id: youtube_channel.id)}")
          end
          if update_last
            last_stat.reload
            last_stat.updated_at = Time.now
            last_stat.current = true
            last_stat.grab_succeded = false
            last_stat.error_type = error_type
            last_stat.save
          else
            stat = if last_stat.present?
              last_stat_dup = last_stat.dup
              YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeChannel' AND current = TRUE", youtube_channel.id).update_all(current: false)
              last_stat_dup.current = true
              last_stat_dup.grab_succeded = false
              last_stat_dup.error_type = error_type
              last_stat_dup
            else
              YtStatistic.new(current: true, grab_succeded: false, error_type: error_type)
            end
            youtube_channel.yt_statistics << stat
          end
        end
      end
    end

    def grab_video_statistics(youtube_video, p_addr, p_port, api_key, update_last = false)
      unless p_addr.present?
        system_accounts = EmailAccount.joins('LEFT OUTER JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all("true").by_is_active("true").by_account_type(EmailAccount.account_type.find_value(:system).value.to_s).where("google_accounts.youtube_data_api_key IS NOT NULL AND google_accounts.youtube_data_api_key <> '' AND ip_addresses.address_target = ?", IpAddress.address_target.find_value("free_proxy").value)
        random_system_account = system_accounts.shuffle.first
        p_addr = random_system_account.ip_address.address
        p_port = random_system_account.ip_address.port
        api_key = random_system_account.email_item.youtube_data_api_key
      end
      tries ||= 3
      last_stat = YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeVideo'", youtube_video.id).order(created_at: :desc).readonly(false).first
      begin
        video_stat = Yt::Video.new(id: youtube_video.youtube_video_id, proxy_address: p_addr, proxy_port: p_port, api_key: api_key)
        attr_hash = {view_count: video_stat.view_count, like_count: video_stat.like_count, dislike_count: video_stat.dislike_count, favorite_count: video_stat.favorite_count, comment_count: video_stat.comment_count, public: video_stat.public?, unlisted: video_stat.unlisted?, private: video_stat.private?, deleted: video_stat.deleted?, failed: video_stat.failed?, rejected: video_stat.rejected?, processed: video_stat.processed?, grab_succeded: true, duration: video_stat.duration, current: true}
        YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeVideo' AND current = TRUE", youtube_video.id).update_all(current: false)
        if update_last
          if last_stat.present?
            last_stat.reload
            last_stat.update_attributes(attr_hash)
          else
            youtube_video.yt_statistics << YtStatistic.create(attr_hash)
          end
        else
          youtube_video.yt_statistics << YtStatistic.create(attr_hash)
        end
      rescue
        unless (tries -= 1).zero?
          retry
        else
          curl_response = %x(curl -x #{p_addr}:#{p_port} -X GET #{youtube_video.url})
          curl_response = CGI.unescapeHTML(curl_response)
          error_type = YtStatistic.error_type.find_value("Other").value
          YtStatistic::ERROR_VIDEO_TYPES.keys.each do |k|
            if curl_response.include?(k)
              error_type = YtStatistic::ERROR_VIDEO_TYPES[k]
              break
            end
          end

          if update_last
            last_stat.reload
            last_stat.updated_at = Time.now
            last_stat.current = true
            last_stat.grab_succeded = false
            last_stat.error_type = error_type
            last_stat.save
            if [1, 5, 6].include?(error_type)
              if error_type == 5
                BotServer.kill_all_zenno
              end
              Utils.pushbullet_broadcast("New blocked youtube video!", "Please check new blocked youtube video #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.youtube_videos_path(id: youtube_video.id)}")
              BroadcasterMailer.new_blocked_youtube_video(youtube_video.id)
            end
          else
            stat = if last_stat.present?
              last_stat_dup = last_stat.dup
              YtStatistic.where("resource_id = ? AND resource_type = 'YoutubeVideo' AND current = TRUE", youtube_video.id).update_all(current: false)
              last_stat_dup.current = true
              last_stat_dup.grab_succeded = false
              last_stat_dup.error_type = error_type
              last_stat_dup
            else
              YtStatistic.new(current: true, grab_succeded: false, error_type: error_type)
            end
            youtube_video.yt_statistics << stat
          end
        end
      end
    end

    def grab_youtube_statistics
      if Setting.get_value_by_name("YoutubeService::YOUTUBE_STATISTICS_ENABLED") == "true"
        system_accounts = EmailAccount.joins('LEFT OUTER JOIN ip_addresses ON ip_addresses.id = email_accounts.ip_address_id LEFT OUTER JOIN google_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN google_account_activities ON google_accounts.id = google_account_activities.google_account_id').by_display_all("true").by_is_active("true").by_account_type(EmailAccount.account_type.find_value(:system).value.to_s).where("google_accounts.youtube_data_api_key IS NOT NULL AND google_accounts.youtube_data_api_key <> '' AND ip_addresses.address_target = ?", IpAddress.address_target.find_value("free_proxy").value)
        #jdrf_youtube_channels = YoutubeChannel.where("client_id = 7 AND youtube_channels.youtube_channel_id IS NOT NULL AND youtube_channels.youtube_channel_id <> ''").by_is_active("true").by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).readonly(false)
        jdrf_youtube_channels = []
        youtube_channels = YoutubeChannel.joins("LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id").by_display_all(nil).by_is_active("true").by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).where("youtube_channels.youtube_channel_id IS NOT NULL AND youtube_channels.youtube_channel_id <> ''").where("email_accounts.client_id IS NOT NULL AND email_accounts.client_id NOT IN (?)", [8,133]).readonly(false)
        youtube_channels = youtube_channels + jdrf_youtube_channels
        youtube_channels.each do |youtube_channel|
          random_system_account = system_accounts.shuffle.first
          p_addr = random_system_account.ip_address.address
          p_port = random_system_account.ip_address.port
          api_key = random_system_account.email_item.youtube_data_api_key
          #grab youtube channels stat
          YoutubeService.delay(queue: DelayedJobQueue::GRAB_YOUTUBE_STATISTICS, priority: 0).grab_channel_statistics(youtube_channel, p_addr, p_port, api_key) unless youtube_channel.blocked
          youtube_channel.youtube_videos.each do |youtube_video|
            if youtube_video.is_active && !youtube_video.deleted && youtube_video.youtube_video_id.present?
              #grab youtube videos stat
              YoutubeService.delay(queue: DelayedJobQueue::GRAB_YOUTUBE_STATISTICS, priority: 0).grab_video_statistics(youtube_video, p_addr, p_port, api_key)
            end
          end
        end
      end
    end

    def send_yt_stat_report
      today_total = YtStatistic.where("created_at > current_date").size
      channels_total = YtStatistic.where("created_at > current_date AND resource_type = 'YoutubeChannel'").size
      videos_total = today_total - channels_total
      channels_failed = YtStatistic.where("created_at > current_date AND resource_type = 'YoutubeChannel' AND grab_succeded = FALSE").size
      videos_failed = YtStatistic.where("created_at > current_date AND resource_type = 'YoutubeVideo' AND grab_succeded = FALSE").size
      landing_pages = ClientLandingPage.where("piwik_id IS NOT NULL").size
      piwik_stat_total = PiwikStatistic.where("created_at > current_date").size
      error_types = YtStatistic.where("created_at > current_date AND error_type IS NOT NULL").group(:error_type).order(error_type: :asc).count(:id)
      error_types_str = ""
      if error_types.present?
        error_types.each {|key, value| error_types_str << "#{YtStatistic.error_type.find_value(key)} - #{value.to_s(:delimited)}\n" }
        error_types_str.strip!
      end
      Setting.get_value_by_name("YoutubeService::YT_PUSHBULLET_RECEIVERS").split(",").map(&:strip).each do |receiver|
        begin
          Pushbullet::Push.create_note(receiver, "Grab Yt statistics report at #{Time.now}", "Total yt statistics: #{today_total.to_s(:delimited)}\nChannel fails: #{channels_failed.to_s(:delimited)} / #{channels_total.to_s(:delimited)}\nVideo fails: #{videos_failed.to_s(:delimited)} / #{videos_total.to_s(:delimited)}\nPiwik statistics: #{piwik_stat_total.to_s(:delimited)} / #{landing_pages.to_s(:delimited)}")
          Pushbullet::Push.create_note(receiver, "Yt statistics report by error types at #{Time.now}", error_types_str) if error_types.present?
        rescue
          ActiveRecord::Base.logger.info "Failed to send pushbullet notification at: #{Time.now}"
        end
      end
    end

    def replace_email_account(old_ea)
      old_ea = EmailAccount.find(old_ea.id)
      client_id = old_ea.client_id
      active_accounts_pool = []
      google_accounts = GoogleAccount.joins("LEFT JOIN google_account_activities ON google_account_activities.google_account_id = google_accounts.id LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id AND email_accounts.email_item_type = 'GoogleAccount'").where("email_accounts.created_at > '2015-02-07 00:00:00' AND email_accounts.client_id IS NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.is_active = TRUE AND email_accounts.recovery_phone_assigned IS NOT FALSE AND email_accounts.deleted IS NOT TRUE AND youtube_channels.id IS NOT NULL AND youtube_channels.channel_type = ? AND youtube_channels.is_active = TRUE AND array_length(google_account_activities.youtube_business_channel, 1) IS NULL", YoutubeChannel.channel_type.find_value(:personal).value).order('email_accounts.recovery_phone_assigned desc NULLS LAST, google_account_activities.recovery_email DESC NULLS LAST, email_accounts.created_at asc')
      google_accounts.each { | ga | active_accounts_pool << ga.email_account if ga.youtube_channels.size == 1 && !RecoveryInboxEmail.where("email_account_id = ? AND date > ? AND email_type in (?)", ga.email_account.id, Time.now - 14.days, [RecoveryInboxEmail.email_type.find_value("Action required: Your Google Account is temporarily disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled").value, RecoveryInboxEmail.email_type.find_value("Google Account has been disabled (FR)").value, RecoveryInboxEmail.email_type.find_value("Google Account disabled").value]).present?}
      ea = active_accounts_pool.first
      YoutubeChannel.where("google_account_id = ? and channel_type = 1", old_ea.email_item_id).update_all(google_account_id: ea.email_item_id)
      ea.client_id = client_id
      ea.bot_server_id = 1
      ea.actual = true
      ea.email_accounts_setup_id = old_ea.email_accounts_setup_id
      old_ea.email_accounts_setup_id = nil
      old_ea.client_id = nil
      ea.locality_id = old_ea.locality_id
      ea.region_id = old_ea.region_id
      old_ea.locality_id = nil
      old_ea.region_id = nil
      ea.save(validate: false)
      old_ea.save(validate: false)
    end

    def reset_youtube_channel(youtube_channel)
      youtube_channel = YoutubeChannel.find(youtube_channel.id)
      YoutubeChannel.where(id: youtube_channel.id).update_all(linked: false, is_active: false, blocked: false, ready: true, channel_art_applied: false, channel_icon_applied: false, fields_to_update: "category,description,keywords,channel_links,business_inquiries_email,overlay_google_plus,recommendations,subscriber_counts,advertisements,channel_icon_url,channel_art_url", filled: false, filling_date: nil, phone_number: nil, posting_time: nil, publication_date: nil, is_verified_by_phone: false, youtube_channel_id: nil)
      youtube_channel.screenshots.destroy_all
      YoutubeService.regenerate_youtube_business_channel_content(youtube_channel, true, [])
    end

    def reset_youtube_video(youtube_video)
      youtube_video = YoutubeVideo.find(youtube_video.id)
      youtube_video.screenshots.destroy_all
      YoutubeService.regenerate_youtube_video_content(youtube_video, [])
      YoutubeVideo.where(id: youtube_video.id).update_all(ready: true, is_active: false, linked: false, rotate_content_date: nil, publication_date: nil, posting_time: nil, fields_to_update: "title,tags,description,thumbnail", youtube_video_id: nil)
      Delayed::Job.enqueue BlendedVideos::ForceBlendJob.new(youtube_video.blended_video_id), queue: DelayedJobQueue::BLEND_VIDEO_SET
    end

    def rotate_video_content
      videos_count = 0
      youtube_setups = YoutubeSetup.distinct.joins("LEFT OUTER JOIN email_accounts_setups ON youtube_setups.email_accounts_setup_id = email_accounts_setups.id LEFT OUTER JOIN email_accounts ON email_accounts_setups.id = email_accounts.email_accounts_setup_id LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id").where("clients.is_active = TRUE AND youtube_setups.rotate_content_frequency IS NOT NULL").uniq
      youtube_setups.each do |youtube_setup|
        content_rotate_limit = youtube_setup.rotate_content_frequency.days.ago
        youtube_videos = YoutubeVideo.joins("LEFT OUTER JOIN youtube_channels ON youtube_channels.id = youtube_videos.youtube_channel_id LEFT OUTER JOIN google_accounts ON google_accounts.id = youtube_channels.google_account_id LEFT OUTER JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id LEFT OUTER JOIN clients ON clients.id = email_accounts.client_id LEFT OUTER JOIN email_accounts_setups ON email_accounts_setups.id = email_accounts.email_accounts_setup_id LEFT OUTER JOIN youtube_setups ON youtube_setups.email_accounts_setup_id = email_accounts_setups.id").where("clients.is_active = TRUE AND youtube_channels.blocked IS NOT TRUE AND email_accounts.is_active = TRUE AND youtube_videos.youtube_video_id IS NOT NULL AND youtube_videos.youtube_video_id <> '' AND youtube_setups.id = ? AND (youtube_videos.rotate_content_date < ? OR (youtube_videos.rotate_content_date IS NULL AND youtube_videos.publication_date < ?))", youtube_setup.id, content_rotate_limit, content_rotate_limit)
        exclude_video_thumbnail = youtube_setup.rotate_youtube_video_thumbnail && youtube_setup.use_youtube_video_thumbnail ? [] : ["thumbnail"]
        youtube_videos.each do |youtube_video|
          videos_count += 1
          YoutubeService.regenerate_youtube_video_content(youtube_video, exclude_video_thumbnail)
        end
      end
      if videos_count > 0
        # Setting.get_value_by_name("YoutubeService::YT_PUSHBULLET_RECEIVERS").split(",").map(&:strip).each do |receiver|
        #   begin
        #     Pushbullet::Push.create_note(receiver, "New rotated videos at #{Time.now}", "Content was rotated for #{videos_count} videos:\n#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.youtube_videos_path(is_active: true, ready: true, deleted: false, linked: false, has_youtube_video_id: true, last_time: 12, field_name: 'updated_at', table_name: 'youtube_videos')}")
        #   rescue
        #     ActiveRecord::Base.logger.info "Failed to send pushbullet notification at: #{Time.now}"
        #   end
        # end
      end
    end

    def generate_youtube_video_title(youtube_video, youtube_setup_var = nil)
      if youtube_setup_var.present?
        email_accounts_setup = youtube_setup.email_accounts_setup
        ea = email_accounts_setup.cities.present? ? EmailAccount.new(locality_id: Geobase::Locality.where("id = ?", email_accounts_setup.cities.shuffle.first.to_i).first.id) : EmailAccount.new(region_id: Geobase::Region.where("id = ?", email_accounts_setup.regions.shuffle.first.to_i).first.id)
        client = email_accounts_setup.client
        industry = client.industry
        source_video = SourceVideo.joins(:client).where("clients.id = ?", client.id).order("random()").first
        product = Product.where(client_id: client.id).last
        donor_client = product.try(:parent).try(:client)
        youtube_setup = youtube_setup_var
      else
        ea = youtube_video.youtube_channel.google_account.email_account
        email_accounts_setup = ea.email_accounts_setup
        youtube_setup = email_accounts_setup.try(:youtube_setup)
        client = email_accounts_setup.client
        industry = client.industry
        blended_video = youtube_video.blended_video
        source_video = blended_video.try(:source_video)
        product = source_video.try(:product)
        donor_client = product.try(:parent).try(:client)
      end

      video_title = if product.present? && email_accounts_setup.present? && youtube_setup.present?
        title_hash = {}
        donor_source_video = client.client_donor_source_videos.where(recipient_source_video_id: source_video.try(:id)).first.try(:source_video)

        business_video_descriptors = youtube_setup.business_video_descriptor
  			business_video_entities = youtube_setup.business_video_entity
  			business_video_subjects = youtube_setup.business_video_subject

        title_pattern = youtube_setup.business_video_title_patterns.shuffle.first
        business_video_title_pattern_arr = title_pattern.split(",")
        title_pattern_in_words = []
        business_video_title_pattern_arr.each do |pattern|
          title_pattern_in_words << YoutubeComponentPattern::PATTERN_COMPONENTS[pattern]
        end

        puts title_pattern_in_words.join(" + ")

  			business_video_descriptors_sample = business_video_title_pattern_arr.include?("A") ? business_video_descriptors.to_a.sample.try(:camelize) : nil
        title_hash["A"] = business_video_descriptors_sample
  			business_video_entities_sample = business_video_title_pattern_arr.include?("B") ? business_video_entities.to_a.sample.try(:camelize) : nil
        title_hash["B"] = business_video_entities_sample

        business_video_industry_component = if industry.nickname.present? && industry.industry_title_components.to_a.present?
          industry_title_groups = [industry.nickname, industry.try(:industry_title_components).to_a.sample.try(:camelize)]
          industry_groups_hash = {
            industry_title_groups[0] => 70,
            industry_title_groups[1] => 30,
          }
          industry_pickup = Pickup.new(industry_groups_hash)
          industry_group = industry_pickup.pick
        else
          industry.nickname || industry.try(:industry_title_components).to_a.sample.try(:camelize)
        end

        business_video_industry_sample = business_video_title_pattern_arr.include?("G") ? business_video_industry_component : nil
        title_hash["G"] = business_video_industry_sample

        if business_video_title_pattern_arr.include?("G") && business_video_entities_sample.present? && business_video_industry_sample.present?
          business_video_entities_sample = [business_video_industry_sample, business_video_entities_sample].join(" ")
          business_video_industry_sample = nil
        end

        business_video_subjects_sample = business_video_title_pattern_arr.include?("D") ? business_video_subjects.to_a.sample.try(:camelize) : nil
        title_hash["D"] = business_video_subjects_sample

        subject_video_title_components = source_video.try(:subject_title_components).to_a + donor_source_video.try(:subject_title_components).to_a
        business_video_subject_videos_sample = business_video_title_pattern_arr.include?("E") ? subject_video_title_components.sample.try(:camelize) : nil
        title_hash["E"] = business_video_subject_videos_sample

        product_title_components = product.try(:subject_title_components).to_a + product.try(:parent).try(:subject_title_components).to_a
        business_video_products_sample = business_video_title_pattern_arr.include?("C") ? product_title_components.sample.try(:camelize) : nil
        title_hash["C"] = business_video_products_sample

        brand_title_component_sample = business_video_title_pattern_arr.include?("H") ? donor_client.try(:nickname) : nil
        title_hash["H"] = brand_title_component_sample

        video_name_delimiter_sample = youtube_setup.present? && youtube_video.nil? ? YoutubeVideo::VIDEO_NAME_DELIMITERS.sample : " "
        video_name_limit = Setting.get_value_by_name("YoutubeVideo::VIDEO_NAME_LIMIT").to_i
        locality_component = if ea.locality.present?
          locality_name_with_full_region_name = ea.locality.name_with_parent_region("@", "full")
          locality_name_with_abbr_region_name = ea.locality.name_with_parent_region(" ", "abbr")
          if [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_full_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.join(video_name_delimiter_sample).strip.size <= video_name_limit && locality_name_with_full_region_name.split("@").uniq.size == 2
  				  [locality_name_with_full_region_name.split("@").join(" "), locality_name_with_abbr_region_name].shuffle.first
          elsif [business_video_descriptors_sample, business_video_entities_sample, business_video_products_sample, locality_name_with_abbr_region_name, business_video_subject_videos_sample, business_video_subjects_sample, business_video_industry_sample].compact.shuffle.join(video_name_delimiter_sample).strip.size <= video_name_limit
            [locality_name_with_abbr_region_name, ea.locality.name_with_parent_region(" ", "")].shuffle.first
          else
            ea.locality.name_with_parent_region(" ", "")
          end
  			else
  				ea.region.name
  			end

        title_hash["F"] = locality_component

        video_title = [business_video_descriptors_sample, brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
        if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
          video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample, business_video_subjects_sample].compact
          if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
            video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subject_videos_sample].compact
            if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
              video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component, business_video_subjects_sample].compact
              if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, business_video_products_sample, locality_component].compact
                if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                  video_title = [brand_title_component_sample, business_video_industry_sample, business_video_entities_sample, locality_component].compact
                  if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                    video_title = [brand_title_component_sample, business_video_entities_sample, locality_component].compact
                    if video_title.shuffle.join(video_name_delimiter_sample).strip.size > video_name_limit
                      video_title = [business_video_entities_sample, locality_component].compact
                    end
                  end
                end
              end
            end
          end
        end
        title = (youtube_setup.business_video_title_components_shuffle ? video_title.shuffle.join(video_name_delimiter_sample).strip.first(video_name_limit) : video_title.join(video_name_delimiter_sample).strip.first(video_name_limit)).squeeze(" ")
        if youtube_setup_var.present?
          {pattern: title_pattern_in_words.join(" + "), title: title, title_hash: title_hash, title_pattern: title_pattern}
        else
          title
        end
      else
        nil
      end
    end
  end
end
