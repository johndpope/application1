class DailyPostingPlan < ActiveRecord::Base
	def self.anything_scheduled?(source_type, date)
		!DailyPostingPlan.where(["source = ? AND scheduled_at::date = ?",source_type, date.strftime("%Y-%m-%d")]).first.nil?
	end
end
