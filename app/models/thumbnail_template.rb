class ThumbnailTemplate < ActiveRecord::Base
  DEFAULT_WIDTH = 480
  DEFAULT_HEIGHT = 480

  validates :name, uniqueness: true

  def render(context = {})
    width = context.delete(:width) || DEFAULT_WIDTH
    height = context.delete(:height) || DEFAULT_HEIGHT
    html = Mustache.render(layout, context)
    IMGKit.new(html, width: width, height: height).to_png
  end
end
