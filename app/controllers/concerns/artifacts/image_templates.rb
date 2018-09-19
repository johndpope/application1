extend ActiveSupport::Concern
module Artifacts
  module ImageTemplates
    IMAGE_TEMPLATES = {
      artifacts_image1:{texts: %w(text1 text2 text3 text4), images: %w(subject_image icon_image)},
      artifacts_image2:{texts: %w(text1), images: %w(subject_image icon_image)},
      artifacts_image3:{texts: %w(text1 text2 text3 text4), images: %w(subject_image icon_image)},
      artifacts_image4:{texts: %w(text1 text2), images: %w(subject_image icon_image)},
      artifacts_image5:{texts: %w(text1 text2 text3), images: %w(subject_image icon_image)}
    }
  end
end
