class Artifacts::Artist < ActiveRecord::Base
  include Reversible
  has_many :audios, class_name: "Artifacts::Audio", foreign_key: "artifacts_artist_id"
end
