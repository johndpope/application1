require 'rails_helper'

RSpec.describe YoutubeVideoAnnotation, type: :model do
  let(:youtube_video_annotation) { YoutubeVideoAnnotation.new }

 describe '.attributes' do
  %w(youtube_video_id annotation_type description style font_size font_color background
	start_time end_time link link_start_time open_in_new_window linked ready).each do |a|
      it(a) { expect(youtube_video_annotation).to respond_to(a) }
    end
  end
end
