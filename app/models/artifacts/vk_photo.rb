class Artifacts::VkPhoto < Artifacts::HumanPhoto
    class << self
        def list(options = {})
          params = {fields: [:first_name, :last_name, :photo_max_orig, :verified, :bdate, :sex]}.merge(options).merge(has_photo: 1)

          vk = VkontakteApi::Client.new CONFIG['vkontakte']['refresh_token']
          response = vk.users.search params

          result = { total: response[:count].to_i }
          result[:items] = response[:items].map do |user|
              next if user[:verified] == 1 # skip celebrities
              source_id = user[:photo_max_orig].to_s.gsub('http://','').split('/')[1]
              Artifacts::VkPhoto.where(source_id: source_id).first_or_initialize do |image|
                  image.source_id = source_id
                  image.source_url = user[:photo_max_orig]
                  image.person_source_id = user[:id]
                  image.person_source_url = "http://vk.com/id#{user[:id]}"
                  image.person_initials = [user[:first_name], user[:last_name]].join(' ').strip
                  image.person_gender = get_gender(user[:sex].to_i)

                  image.person_birth_year = unless user[:bdate].blank?
                      user[:bdate][/(19|20)\d{2}/]
                  end

                  image.person_age = Time.now.year - image.person_birth_year unless image.person_birth_year.blank?
              end
          end.compact
          result
        end

        private
            def get_gender(sex)
                case sex
                    when 1
                        :female
                    when 2
                        :male
                    else
                        nil
                end
            end
    end

    def import
        self.file = self.source_url
        save!
    end
end
