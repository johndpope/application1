class Templates::ImageTemplateText < ActiveRecord::Base
  belongs_to :image_template
  validates :name, presence: true
  validates :name, uniqueness: {scope: :image_template_id, message: "Text for template must be uniq"} #уникальность в таб.texts в расках 1 шаблона

end
