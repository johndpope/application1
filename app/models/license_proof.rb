class LicenseProof < ActiveRecord::Base
  has_many :social_images, class_name: 'Social::Image', foreign_key: 'license_proof_id', dependent: :destroy

  has_attached_file :file
  validates_attachment_content_type :file, content_type: ["application/pdf"], message: "Invalid content type (only png)"
  validates_attachment_presence :file

  def to_json_format
    {
      "id" => read_attribute(:id),
      "name" => read_attribute(:file_file_name)
    }
  end

end
