class YoutubeComponentPattern < ActiveRecord::Base
  include Reversible
  PATTERN_COMPONENTS = {"A" => "Descriptor", "B" => "Entity", "C" => "Product", "D" => "Subject", "E" => "Subject video", "F" => "Location", "G" => "Industry", "H" => "Brand"}
  COMPONENT_TYPES = {"channel_title" => 1, "channel_description" => 2, "channel_tags" => 3, "video_title" => 4, "video_description" => 5, "video_tags" => 6}
  extend Enumerize
	enumerize :component_type, in: COMPONENT_TYPES

  before_destroy :remove_in_youtube_setups

  def name
    title = []
    self.components.split(",").each {|i| title << PATTERN_COMPONENTS[i]}
    title.join(' + ')
  end

  private

    def remove_in_youtube_setups
      YoutubeSetup.all.readonly(false).each do |youtube_setup|
        %w(business personal).each do |type|
          patterns_array = youtube_setup[:"#{type}_#{self.component_type.to_s}_patterns"].to_a
          if patterns_array.delete(self.components.to_s)
            YoutubeSetup.where(id: youtube_setup.id).update_all(:"#{type}_#{self.component_type.to_s}_patterns" => patterns_array)
          end
        end
      end
    end
end
