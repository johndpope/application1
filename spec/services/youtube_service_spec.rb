require 'rails_helper'

RSpec.describe YoutubeService do
  describe '.spin_paragraphs' do
    let(:type) { %w(business personal).shuffle.first }
    let(:target) { %w(channel video).shuffle.first }
    let(:text) {
      %Q[
        Ernest Hemingway is the notorious tough guy of modern American letters,
        but it would be hard to find a more tender and rapturous love story than
        A Farewell to Arms. It would also be hard to find a more harrowing American
        novel about World War I. Hemingway masterfully interweaves these dual narratives
        of love and war, joy and terror, and—ultimately—liberation and death.
      ]
    }
    let(:youtube_setup) { FactoryGirl.create(:youtube_setup) }
    
    before do
      youtube_setup.send("#{type}_#{target}_description_paragraphs").build(
        title: 'A Farewell to Arms',
        body: text
      )
      youtube_setup.save!
    end


    it 'retreieves spintax from WordAI', vcr: true do
      YoutubeService.spin_paragraphs(youtube_setup)
      paragraph = youtube_setup.reload.send("#{type}_#{target}_description_paragraphs").first
      expect(paragraph.spintax).to be_present
    end
  end
end
