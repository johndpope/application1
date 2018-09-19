module YoutubeChannelArt
    TMPLS = {
        'youtube_channel_art1' => {images:[:background_image], texts:[:text1, :text2]},
        'youtube_channel_art2' => {images:[:background_image, :subject_image1, :subject_image2, :subject_image3], texts:[:text1, :text2]},
        'youtube_channel_art3' => {images:[:background_image, :subject_image1, :subject_image2], texts:[:text]},
        'youtube_channel_art4' => {images:[:background_image], texts:[:text1, :text2]},
        'youtube_channel_art5' => {images:[:background_image], texts:[:text1, :text2, :text3], location_label: :text0},
        'youtube_channel_art6' => {images:[:subject_image1, :subject_image2], texts:[:text1, :text2], location_label: :text0},
        'youtube_channel_art7' => {images:[:background_image, :subject_image], texts:[:text1, :text2]},
        'youtube_channel_art8' => {images:[:background_image], texts:[:text1, :text2]},
        'youtube_channel_art9' => {images:[:background_image, :subject_image], texts:[:text1], location_label: :text0},
        'youtube_channel_art10' => {images:[:background_image, :subject_image], texts:[:text1, :text2]}
    }

    def generate_icon
        send("generate_#{channel_type}_channel_icon")
    end

    def generate_art
        send("generate_#{channel_type}_channel_art")
    end

    private
        def tag_list
            eval("google_account.email_account.email_accounts_setup.youtube_setup.#{channel_type}_channel_tags_paragraphs.pluck(:body)")
        end

        def generate_personal_channel_icon
            gender = google_account.email_account.gender.try(:to_sym)
            wheres = Hash.new.tap{|where| where[:person_gender] = Artifacts::HumanPhoto::GENDERS[gender] unless gender.blank?}
            photos_in_use = Attribution.where(resource_type: YoutubeChannel, component_type: Artifacts::HumanPhoto).pluck(:component_id)
            human_photo = Artifacts::HumanPhoto.where(wheres).where.not(id: photos_in_use).order('random()').first
            unless human_photo.blank?
                self.channel_icon = open(human_photo.file.path)
                save!

                Attribution.create!(resource: self, component: human_photo)
            end
        end

        def generate_business_channel_icon
        end

        def generate_personal_channel_art
            tmp_channel_art = File.join('/tmp', SecureRandom.uuid)
            begin
                images_in_use = Attribution.where(resource_type: YoutubeChannel, component_type: Artifacts::Image).pluck(:component_id)

                #selection from images tagged as "social_channel_art"
                sca_image = Artifacts::Image.with_tags(['social_channel_art']).with_aspect_ratio(1.33, 1600).downloaded.where.not(id: images_in_use).order('random()').first
                unless sca_image.blank?
                    RmagickTemplates::YoutubeChannelArt.new(background: sca_image.file.path).render.write(tmp_channel_art){self.quality = 72}
                    self.channel_art = open(tmp_channel_art)
                    save!

                    Attribution.create!(resource: self, component: sca_image)
                end
            ensure
                FileUtils.rm_rf tmp_channel_art
            end
        end

        def generate_business_channel_art
            tmp_channel_art = File.join('/tmp', SecureRandom.uuid)
            tmp_channel_art_file = File.join(tmp_channel_art, 'youtube_channel_art.jpg')
            FileUtils.mkdir_p tmp_channel_art
            #refactor
            begin
                client = google_account.email_account.client
                tmpl_name = TMPLS.map{|k,v|k}[rand(0..TMPLS.size - 1)]
                params = {}
                target_client_ids = [client.id] + client.donors.map(&:id)

                TMPLS[tmpl_name][:images].each do |i|
                    image = Artifacts::Image.downloaded.with_aspect_ratio(0.5, 800).where.not(file_content_type: 'image/svg+xml').where(client_id: target_client_ids).order('random()').first
                    if !image.blank? && !image.file_file_name.blank? && File.exist?(image.file.path)
                      params[i] = image.file.path
                      Attribution.create!(resource: self, component: image)
                    end
                end

                TMPLS[tmpl_name][:texts].each do |text|

                end

                unless TMPLS[tmpl_name][:location_label].blank?
                  params[TMPLS[tmpl_name][:location_label]] = google_account.email_account.location.name
                end

                unless TMPLS[tmpl_name].blank?

                end

                ("RmagickTemplates::#{tmpl_name.camelize}".constantize).new(params).render.write(tmp_channel_art_file){self.quality = 72}
                self.channel_art = open(tmp_channel_art_file)
                save!
            ensure
                FileUtils.rm_rf tmp_channel_art
            end
        end
end
