CreateMediaInfoJob = Struct.new(:object_type, :object_id, :file_path) do
	def perform
		ActiveRecord::Base.transaction do
			mi = Mediainfo.new file_path
			MediaInfo.create! object_type: object_type, object_id: object_id, value: Hash.from_xml(mi.raw_response).to_json
		end
	end

	def max_attempts
		5
	end

	def max_run_time
		120 #seconds
	end

	def reschedule_at(current_time, attempts)
		current_time + 4.hours
	end
end
