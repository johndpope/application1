class Templates::ImageTemplateImage < ActiveRecord::Base
  belongs_to :image_template

  validates :name, presence: {message: "name value can not be blank"}
  validates :name, uniqueness: {scope: :image_template_id, message: "Images name must be uniq"}
  validates :width, presence: {message: "width value can not be blank"}
  validates :height, presence: {message: "height value can not be blank"}

end
