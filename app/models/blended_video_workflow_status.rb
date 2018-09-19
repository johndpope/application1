class BlendedVideoWorkflowStatus < ActiveRecord::Base
	belongs_to :blended_video
	validates :blended_video_id, presence: true, uniqueness: true

	after_initialize {self.workflow_status ||= {}}
end
