class CaseTag < ActiveRecord::Base
	has_one :tag, :as=>:tag_source, dependent: :destroy

	belongs_to :case_type, foreign_key: :case_type_id
	belongs_to :language, foreign_key: :language_id

	validates :case_type_id, presence: true
	validates :language_id, presence: true
	validates :name, presence: true
end
