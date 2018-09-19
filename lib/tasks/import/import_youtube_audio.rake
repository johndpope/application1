namespace :db do
  namespace :seed do
    task :import_youtube_audio => :environment do
      puts "import youtube audio task started"
      bot_server_url = Setting.get_value_by_name("EmailAccount::BOT_URL")
      csv_url = bot_server_url + '/out/youtube_audio_library/data/music.csv'
      open(csv_url, 'r:utf-8') do |f|   # don't forget to specify the UTF-8 encoding!!
        data = SmarterCSV.process(f, {col_sep: ";", row_sep: "\r\n", headers_in_file: false, user_provided_headers: %w(number title duration artist genre popularity monetization attribution music_type music_path screen_path)})
        data.each do |row|
          duration_array = row[:duration].split(":")
          genre_array = row[:genre].to_s.split(" | ")
          genre_string = genre_array.first.to_s.strip
          mood_string = genre_array.second.to_s.downcase.strip
          audio_file = bot_server_url + row[:music_path]
          audio_json = {
            title: row[:title].to_s.strip,
            duration: duration_array.first.to_f * 60 + duration_array.second.to_f,
            popularity: row[:popularity].to_f,
            monetization: row[:monetization],
            attribution_required: row[:attribution] == "Attribution not required" ? Artifacts::Audio.attribution_required.find_value(:attribution_notrequired).value : Artifacts::Audio.attribution_required.find_value(:attribution_required).value,
            license_type: Artifacts::Audio.license_type.find_value('Standard Youtube License').value,
            sound_type: Artifacts::Audio.sound_type.find_value(:sound_music).value,
            mood: Artifacts::Audio.mood.find_value(:"#{mood_string}").try(:value)
          }
          artist = if row[:artist].to_s.strip.present?
            artist = Artifacts::Artist.where("LOWER(name) = ?", row[:artist].to_s.downcase.strip).first_or_initialize
            unless artist.persisted?
              artist.name = row[:artist].strip
              artist.save
            end
            artist
          else
            nil
          end

          genre = if genre_string.present?
            genre = Genre.where("LOWER(name) = ?", genre_string.downcase).first_or_initialize
            unless genre.persisted?
              genre.name = genre_string
              genre.save
            end
            genre
          else
            nil
          end

          unless Artifacts::YoutubeAudio.where({title: audio_json[:title], artifacts_artist_id: artist.try(:id), duration: audio_json[:duration]}).present?
            audio = Artifacts::YoutubeAudio.new(audio_json)
            f = nil
            begin
              f = open(audio_file)
            rescue
              puts "!!! Sound Not found !!!"
            end
            if f.present?
      				audio.file = f
              audio.file_file_name = "#{audio.title}.mp3"
              if audio.save
                audio.genres << genre if genre.present?
                audio.save_screenshot(bot_server_url + row[:screen_path])
                puts "*** Audio #{row[:number]} - #{row[:title]} successfully saved. ***"
              else
                puts "---Audio #{row[:number]} - #{row[:title]} didn't save! ---"
              end
              f.close unless f.closed?
            end
          else
            puts "Audio already exists!"
          end
        end
      end
      puts "import youtube audio task finished"
    end

    task :import_youtube_sounds => :environment do
      puts "import youtube sounds task started"
      bot_server_url = Setting.get_value_by_name("EmailAccount::BOT_URL")
      csv_url = bot_server_url + '/out/youtube_audio_library/data/sound.csv'
      open(csv_url, 'r:utf-8') do |f|   # don't forget to specify the UTF-8 encoding!!
        data = SmarterCSV.process(f, {col_sep: ";", row_sep: "\r\n", headers_in_file: false, user_provided_headers: %w(number title duration popularity attribution music_type category music_path screen_path)})
        data.each do |row|
          duration_array = row[:duration].split(":")
          audio_file = bot_server_url + row[:music_path]
          audio_json = {
            title: row[:title].to_s.strip,
            duration: duration_array.first.to_f * 60 + duration_array.second.to_f,
            popularity: row[:popularity].to_f,
            attribution_required: row[:attribution].to_s.strip == "Attribution not required" ? Artifacts::Audio.attribution_required.find_value(:attribution_not_required).value : Artifacts::Audio.attribution_required.find_value(:attribution_required).value,
            license_type: Artifacts::Audio.license_type.find_value('Standard Youtube License').value,
            sound_type: Artifacts::Audio.sound_type.find_value(:sound_effect).value,
            audio_category: Artifacts::Audio.audio_category.find_value(row[:category].to_s.strip).try(:value),
            description: "YouTube Terms of Service Page Link - https://www.youtube.com/t/terms and Screenshot Link http://broadcaster.beazil.net/youtube_terms_of_service.png"
          }
          email_account = EmailAccount.find(19446)
          existing_audio = Artifacts::YoutubeAudio.where({title: audio_json[:title], duration: audio_json[:duration], audio_category: audio_json[:audio_category]}).first
          unless existing_audio.present?
            audio = Artifacts::YoutubeAudio.new(audio_json)
            f = nil
            begin
              f = open(audio_file)
            rescue
              puts "!!!Sound #{row[:number]} - #{row[:title]} not found !!!"
            end
            if f.present?
      				audio.file = f
              audio.file_file_name = "#{audio.title}.mp3"
              if audio.save
                screenshot = audio.save_screenshot(bot_server_url + row[:screen_path])
                if screenshot.present? && screenshot.image.present?
                  begin
                    username = email_account.email.strip.gsub("@gmail.com", "")
                    screen = Screenshot.new
                    screen.image = screenshot.image
                    extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
                    screen.image_file_name = File.basename(username)[0..-1] + extension
                    screen.removable = false
                    email_account.screenshots << screen
                  rescue
                  end
                end
                puts "*** Sound #{row[:number]} - #{row[:title]} successfully saved. ***"
              else
                puts "---Sound #{row[:number]} - #{row[:title]} didn't save! ---"
              end
              f.close unless f.closed?
            end
          else
            unless existing_audio.screenshots.present?
              screenshot = existing_audio.save_screenshot(bot_server_url + row[:screen_path])
              if screenshot.present? && screenshot.image.present?
                begin
                  username = email_account.email.strip.gsub("@gmail.com", "")
                  screen = Screenshot.new
                  screen.image = screenshot.image
                  extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
                  screen.image_file_name = File.basename(username)[0..-1] + extension
                  screen.removable = false
                  email_account.screenshots << screen
                rescue
                end
              end
            end
            unless existing_audio.screenshots.present?
              screenshot = existing_audio.save_screenshot(bot_server_url + row[:screen_path].gsub(".jpg", "_.jpg"))
              if screenshot.present? && screenshot.image.present?
                begin
                  username = email_account.email.strip.gsub("@gmail.com", "")
                  screen = Screenshot.new
                  screen.image = screenshot.image
                  extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
                  screen.image_file_name = File.basename(username)[0..-1] + extension
                  screen.removable = false
                  email_account.screenshots << screen
                rescue
                end
              end
            end
            puts "Sound already exists!"
          end
        end
      end
      puts "import youtube sound task finished"
    end
  end
end
