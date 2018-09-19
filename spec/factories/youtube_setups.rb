FactoryGirl.define do
  factory :youtube_setup do
    client { FactoryGirl.build(:client) }
    email_accounts_setup { FactoryGirl.build(:email_accounts_setup) }
    after(:build) do |youtube_setup|
      %w(business personal).each do |i|
        %w(channel video).each do |j|
          youtube_setup.send("#{i}_#{j}_tags_paragraphs").build(
            title: Faker::Lorem.sentence,
            body: Faker::Lorem.words.join(', ')
          )
        end
      end
    end
  end
end
