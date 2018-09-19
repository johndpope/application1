module Templates
	module AaeProjects
		CreateBlendedVideoJob = Struct.new(:client_id, :product_id, :source_video_id, :location_id, :location_type, :render_machine) do
	    def perform
				ActiveRecord::Base.transaction do
					RenderingMachine.where.not(is_active: false).to_a.each do |rm|

					end
				end
	    end

	    def max_attempts
	      5
	    end

	    def reschedule_at(current_time, attempts)
	      current_time + 1.hours
	    end

			def success(job)

			end
	  end
	end
end
