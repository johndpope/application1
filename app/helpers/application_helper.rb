module ApplicationHelper
	%w(title header small_header).each do |m|
    define_method(m){|text| content_for(m.to_sym){text}}
  end

	def video_type_name_grouped_options(include_subject = true, include_general_transition = true)
		video_chunks = Templates::VIDEO_CHUNK_TYPES.keys
		video_chunks << :subject if include_subject == true
		transitions = Templates::TRANSITION_TYPES.reject{|k,v| v.blank?}.keys
		transitions << :transition if include_general_transition == true
		types = {'videos' => video_chunks, 'transitions' => transitions}

		res = {}
		%w(videos transitions).each{|group| res[I18n.t(group)] = types[group].collect{|t| [I18n.t("templates.video_types.#{t.to_s}"), t.to_s]}}
		res
	end

	def video_resolution_options
		SourceVideo::VideoResolution::TYPES.keys.collect{|t|[I18n.t("video_resolutions.#{t.to_s}"), t.to_s]}
	end

	def client_business_type_options
		Client::BUSINESS_TYPES.map{|k,v|[I18n.t("client.business_types.#{k.to_s}"), v]}
	end

	def row_nr(index, page, limit)
		index + ((page.abs == 0 ? 1 : page.abs)-1)*limit
	end
end
