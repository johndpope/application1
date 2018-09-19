require 'rails_helper'

RSpec.describe YoutubeSetup, type: :feature do

  describe '/new' do
    let(:client) { FactoryGirl.create(:client) }
    let(:product) { FactoryGirl.create(:product, client: client) }
    let(:contract) { FactoryGirl.create(:contract, product: product, client: client) }
    let!(:email_accounts_setup) do
      FactoryGirl.create(:email_accounts_setup, contract: contract, client: client)
    end
    let(:admin_user) { FactoryGirl.create(:admin_user) }
    let(:art_text_variants) do
      3.times.map { Faker::Lorem.sentence }.join(";\n")
    end
    let(:paragraph_builder) { lambda { FactoryGirl.build(:paragraph) } }
    %w(business personal).each do |type|
      let(:"#{type}_inquiries_email") { Faker::Internet.email }
      let(:"#{type}_channel_art_references") do
        2.times.map { FactoryGirl.build(:reference, description: Faker::Lorem.sentence.first(30)) }
      end

      %w(channel video).each do |target|
        %w(entity subject descriptor).each do |field|
          let(:"#{type}_#{target}_#{field}") { Faker::Lorem.words.uniq }
        end
      end
    end

    before do
      sign_in(admin_user)
    end

    it 'fills the form and creates a new record', js: true do
      visit new_youtube_setup_path(client_id: client.id)

      ['youtube channel icon', 'youtube video thumbnail', 'google plus cover photo',
       'youtube channel art text'].each do |option|
        find('label', text: "Use #{option}").click
      end
      fill_in 'youtube_setup_youtube_channel_art_text', with: art_text_variants
      %w(business personal).each do |type|
        value = send(:"#{type}_inquiries_email")
        fill_in "youtube_setup_#{type}_inquiries_email", with: value

        %w(channel video).each do |target|
          %w(entity subject descriptor).each do |field|

            value = send(:"#{type}_#{target}_#{field}").map { |w| { id: w, text: w } }.to_json
            page.execute_script %Q[
              $('#youtube_setup_#{type}_#{target}_#{field}_csv').select2('data', #{value})
            ]
          end
        end

        # Fill in reference links
        within "##{type}_channel_art_references" do
          references = send("#{type}_channel_art_references")
          references.each do |reference|
            click_link 'Add Reference'
            inputs = all('input[type=text]')
            fill_in inputs[-2][:id], with: reference.url
            fill_in inputs[-1][:id], with: reference.description
          end
        end

        %w(description tags).each do |field|
          within "##{type}-#{field}-accordion" do
            %w(channel video).each do |target|
              find('h4.panel-title a', text: "#{type} #{target} #{field}".titleize).click
              within "##{type}_#{target}_#{field}" do
                fill_section = lambda do
                  paragraph = paragraph_builder.call
                  input = all('.fields input[type=text]').last
                  fill_in input[:id], with: paragraph.title
                  textarea = all('.fields textarea').last
                  fill_in textarea[:id], with: paragraph.body
                end
                fill_section.call
                click_link 'Add Section'
                fill_section.call
              end
            end
          end
        end
      end
      click_button 'Create Youtube setup'
      within '#youtube_setups_list' do
        expect(page).to have_selector('span.badge.bg-blue', text: 1)
      end
      youtube_setup = YoutubeSetup.last
      fields = []
      %w(business personal).each do |type|
        fields << "#{type}_inquiries_email"
        %w(channel video).each do |target|
          %w(entity subject descriptor).each do |field|
            fields << :"#{type}_#{target}_#{field}"
          end
        end
        fields.each do |accessor|
          expect(youtube_setup.send(accessor)).to eq(send(accessor))
        end
        accessor = "#{type}_channel_art_references"
        send(accessor).each do |reference|
          expect(youtube_setup.send(accessor).where(url: reference.url, description: reference.description)).to be_any
        end
      end
    end
  end
end
