class Transition < ActiveRecord::Base
	has_one :video_part, as: :video_part_item, dependent: :destroy
end
