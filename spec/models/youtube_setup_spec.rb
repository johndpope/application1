require 'rails_helper'
require 'models/concerns/paragraphable'
require 'models/concerns/csv_accessor'
require 'models/concerns/referable'

RSpec.describe YoutubeSetup, type: :model do
  let(:youtube_setup) { FactoryGirl.build(:youtube_setup) }

  it { expect(youtube_setup).to be_valid }

  paragraph_groups = []

  %w(business personal).each do |type|

    it_behaves_like 'has references for', :"#{type}_channel_art"

    %w(channel video).each do |target|

      %w(entity subject descriptor).each do |field|
        it_behaves_like 'has CSV accessors for', :"#{type}_#{target}_#{field}"
      end

      %w(description tags).each do |field|
        paragraph_groups << :"#{type}_#{target}_#{field}"
      end
    end
  end

  it_behaves_like 'has paragraphs for', *paragraph_groups

  describe '.attributes' do
    [
      'use_youtube_channel_art', 'use_youtube_channel_icon', 'use_youtube_video_thumbnail',
      'use_google_plus_cover_photo', 'youtube_channel_art_text', 'client_id',
      'email_accounts_setup_id', 'business_inquiries_email', 'personal_inquiries_email', 'adwords_account_name',
			'adwords_campaign_name', 'adwords_campaign_type', 'adwords_campaign_subtype', 'adwords_campaign_networks_youtube_search',
			'adwords_campaign_networks_youtube_videos', 'adwords_campaign_networks_include_video_partners', 'adwords_campaign_languages',
			'adwords_campaign_start_date', 'adwords_campaign_end_date', 'adwords_campaign_group_name', 'adwords_campaign_group_video_ad_format',
			'adwords_campaign_group_display_url', 'adwords_campaign_group_final_url', 'adwords_campaign_group_ad_name',
			'adwords_campaign_group_headline', 'adwords_campaign_group_description_1', 'adwords_campaign_group_description_2',
			'call_to_action_overlay_headline', 'call_to_action_overlay_display_url', 'call_to_action_overlay_destination_url',
			'call_to_action_overlay_enabled_on_mobile', 'use_call_to_action_overlay', 'protected_words', 'use_social_links_in_youtube_video_description',
      'use_youtube_video_annotations', 'use_youtube_video_cards', 'use_call_to_action_overlays'
    ].each do |a|
      it(a) { expect(youtube_setup).to respond_to(a) }
    end
  end

  %w(business personal).each do |type|
    %w(channel video).each do |target|
      describe "##{type}_#{target}_description" do
        limit = YoutubeSetup.const_get("#{target.upcase}_DESCRIPTION_LIMIT")
        it "should stay under #{limit} characters" do
          while youtube_setup.send("#{type}_#{target}_description").length <= limit
            youtube_setup.send("#{type}_#{target}_description_paragraphs").build(
              title: Faker::Lorem.sentence,
              body: Faker::Lorem.paragraph
            )
          end
          expect(youtube_setup).to_not be_valid
        end
      end
    end

    # %w(channel video).each do |target|
    #   describe "##{type}_#{target}_tags" do
    #     it 'should be present' do
    #       youtube_setup.send("#{type}_#{target}_tags_paragraphs").delete_all
    #       expect(youtube_setup).to_not be_valid
    #     end
    #   end
    # end

    describe "##{type}_inquiries_email" do
      let(:valid_email) { Faker::Internet.email }
      it 'should match the conventional pattern' do
        ['sample', 'jqpublic@', 'foobar.com'].each do |email|
          youtube_setup.send("#{type}_inquiries_email=", email)
          expect(youtube_setup).to_not be_valid
        end
        youtube_setup.send("#{type}_inquiries_email=", valid_email)
        expect(youtube_setup).to be_valid
      end
    end

    %w(entity subject descriptor).each do |field|
      describe "##{type}_video_#{field}" do
        it 'is an array' do
          expect(youtube_setup.send("#{type}_video_#{field}")).to be_an(Array)
        end
      end
    end
  end
end
