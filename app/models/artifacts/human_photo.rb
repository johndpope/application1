class Artifacts::HumanPhoto < ActiveRecord::Base
    has_attached_file :file, styles: { w150: '150x150>', google_avatar: {processors: [:google_avatar]}}
    validates_attachment_content_type :file,
      content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"]

    GENDERS =   {male: 1, female: 2}

    extend Enumerize
    enumerize :person_gender, in: GENDERS

    def exists?
      source_id && self.class.where(source_id: source_id.to_s).any?
    end
end
