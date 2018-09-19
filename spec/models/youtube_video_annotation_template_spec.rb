require 'rails_helper'

RSpec.describe YoutubeVideoAnnotationTemplate, type: :model do
  let(:youtube_video_annotation_template) { YoutubeVideoAnnotationTemplate.new }

 describe '.attributes' do
  %w(annotation_type description style font_size font_color background
	start_time end_time link link_start_time open_in_new_window linked ready youtube_setup_id).each do |a|
      it(a) { expect(youtube_video_annotation_template).to respond_to(a) }
    end
  end
end
