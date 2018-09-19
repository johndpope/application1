module Templates::AaeProjectDynamicTextService
	class << self
		def select_texts_for_aae_template(aae_template, text_type, source_video, location: nil, blended_video_chunk_id: nil)
			limit = aae_template.aae_project_texts.with_text_type(text_type).where.not(is_static: true).count
			texts = select_texts(text_type, source_video, location: location, blended_video_chunk_id: blended_video_chunk_id, limit: limit)
			if !%w(location state web_site phone facebook twitter youtube google_plus instagram linkedin pinterest credits_link video_subject likes_and_views_tagline credits_client_disclaimer).include?(text_type) && texts.size < limit
				raise "Not enough [#{text_type}] strings. #{limit - texts.size} dynamic strings missing"
			end
			texts
		end

		def select_texts(text_type, source_video, location: nil, blended_video_chunk_id: nil, limit: nil, length_threshold: nil)
			return [] if limit == 0

			texts = []
			scope = ::Templates::AaeProjectDynamicText.where.not(value: nil).with_text_type(text_type).order('RANDOM()')
			scope = scope.where("length(value) <= ?", length_threshold) if length_threshold

			if %w(location state web_site phone facebook twitter youtube google_plus instagram linkedin pinterest credits_link).include?(text_type)
				texts = if %w(location state).include?(text_type)
									[location.formatted_name(primary_region_code: true)]
								elsif text_type == 'web_site'
									[source_video.client.try(:website).to_s]
								elsif text_type == 'phone'
									source_video.client.phones.to_a.map{|p|p.split(":").last.to_s}.uniq.reject(&:blank?)
								elsif %w(facebook twitter youtube google_plus instagram linkedin pinterest).include?(text_type)
									[source_video.client.try("#{text_type}_url")]
								elsif	text_type == 'credits_link'
									[credits_link(blended_video_chunk_id)]
								end
				return texts
			elsif text_type == 'client'
				texts << source_video.client.name if(length_threshold.nil? || (!length_threshold.nil? && source_video.client.name.size <= length_threshold))
				texts << scope.where(client_id: source_video.client.id).pluck(:value)
				return texts.flatten
			end

			cdsv = source_video.client.client_donor_source_videos.where(recipient_source_video_id: source_video.id).first
			donor_source_video ||= cdsv.try(:source_video)
			donor_product = if !donor_source_video.nil?
				donor_source_video.product
			elsif !source_video.product.parent.nil?
				source_video.product.parent
			end
			donor_client = donor_product.try(:client)

			#Step 1. Select Subject Video specific texts
			(texts << scope.
				where(subject_video_id: source_video.id).
				limit((if !limit.nil?
					if texts.size < limit; limit - texts.size; else; 0; end
				else
					nil
				end)).
				pluck(:value)
			).flatten!

			return texts unless ((source_video.use_only_sv_specific_dyn_text_strings? && texts.empty?) || !source_video.use_only_sv_specific_dyn_text_strings?)

			#Step 2. Select Donor Subject Video specific texts if subject video is recipient
			unless donor_source_video.nil?
				(texts << scope.
					where(subject_video_id: donor_source_video.id).
					limit((if !limit.nil?
						if texts.size < limit; limit - texts.size; else; 0; end
					else
						nil
					end)).
					pluck(:value)
				).flatten!
			end

			#Step 3. Select Product specific texts
			(texts << scope.
				where(product_id: source_video.product_id).
				limit((if !limit.nil?
					if texts.size < limit; limit - texts.size; else; 0; end
				else
					nil
				end)).
				pluck(:value)
			).flatten!

			#Step 4. Select Client Specific Texts
			(texts << scope.
				where(client_id: source_video.client.id, product_id: nil, subject_video_id: nil).
				limit((if !limit.nil?
					if texts.size < limit; limit - texts.size; else; 0; end
				else
					nil
				end)).
				pluck(:value)
			).flatten!

			unless donor_product.nil?
				#Step 5. Select Donor Product specific texts
				(texts << scope.
					where(product_id: donor_product.id).
					limit((if !limit.nil?
						if texts.size < limit; limit - texts.size; else; 0; end
					else
						nil
					end)).
					pluck(:value)
				).flatten!

				#Step 6. Select Donor Client Specific Texts
				(texts << scope.
					where(client_id: donor_client.id, product_id: nil, subject_video_id: nil).
					limit((if !limit.nil?
						if texts.size < limit; limit - texts.size; else; 0; end
					else
						nil
					end)).
					pluck(:value)
				).flatten!
			end

			texts
		end

		def credits_link(blended_video_chunk_id = nil)
			blended_video_id = if blended_video_chunk_id.nil? #test OR sandbox
														Random.rand
													else #distribution
														BlendedVideoChunk.find(blended_video_chunk_id).blended_video.id
													end
			"#{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.public_credits_video_path(blended_video_id)}"
		end
	end
end
