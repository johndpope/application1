module ArtifactsHelper
  def popular_image_tags
    Artifacts::Image.distribution_by_tag.keys.first(12)
  end

  def popular_image_places
    Artifacts::Image.distribution_by_city.keys.first(12)
  end
end
