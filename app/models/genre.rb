class Genre < ActiveRecord::Base
  has_and_belongs_to_many :artifacts_audios, class_name: 'Artifacts::Audio', :join_table => "artifacts_audios_genres"

  validates_presence_of :name
  validates_uniqueness_of :name, case_sensitive: false

  before_save do
    self.hash_value = name.downcase.hash unless name.nil?
  end
end
