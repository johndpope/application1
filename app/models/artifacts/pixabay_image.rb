module Artifacts
  class PixabayImage < Image
    class << self
      def list(options = {})
        options[:limit] ||= Artifacts::Image::DEFAULTS[:limit]
        uri = URI('https://pixabay.com/api/')
        uri.query = URI.encode_www_form({
          key: CONFIG['pixabay'][0]['key'],
          q: options[:q],
          response_group: 'high_resolution',
          page: options[:page],
          per_page: options[:limit]
        }.merge(api_credentials))

        response = JSON.parse(Net::HTTP.get_response(uri).body)
        result = { total: response['totalHits'] }
        unless options[:show_imported].present?
          imported_source_ids = Artifacts::PixabayImage.select(:source_id).distinct.pluck(:source_id)
          response['hits'].reject! { |item| imported_source_ids.include?(item['id_hash'].to_s)}
        end
        unless options[:show_rejected].present?
          response['hits'].reject! { |item| options[:rejected_images_ids].include?(item['id_hash'].to_s)}
        end
        persisted_images = Artifacts::PixabayImage.where(source_id: response['hits'].map {|photo| photo['id_hash'].to_s} )
        result[:items] = response['hits'].map do |photo|
          image = persisted_images.select { |img| img.source_id == photo['id_hash'].to_s }.first
          image = Artifacts::PixabayImage.new(source_id: photo['id_hash'].to_s) unless image.present?
          image.title = photo['id_hash'].to_s
          image.source_tag_list = []
          image.url = photo['webformatURL']
          image.url_o = photo['webformatURL']
          image.height = photo['imageHeight'].to_i
          image.width = photo['imageWidth'].to_i
          image.page_url = "https://pixabay.com/goto/" + photo['id_hash'].to_s
          image
        end
        result
      end

      def api_credentials
        CONFIG['pixabay'].shuffle.first.symbolize_keys!
      end
    end

    def import
      super
      high_res_info = get_high_res_info['hits'].first
      self.url = high_res_info['imageURL']
      self.license_name = 'Creative Commons Deed CC0'
      self.license_url = 'http://creativecommons.org/publicdomain/zero/1.0/deed.en'
      self.file = URI.parse(url)

      #self.source_tag_list = get_source_tags
      self.page_url = "https://pixabay.com/goto/" + high_res_info['id_hash']
      self.title = high_res_info['id_hash']
      self.author = Artifacts::PixabayAuthor.where(username: high_res_info['user']).first_or_create! do |author|
        author_url = "https://pixabay.com/users/#{high_res_info['user']}"
        author_page = Nokogiri::HTML(open(author_url))
        avatar_path = author_page.css('#hero img').try(:first).try(:attr, 'src')
        avatar_path = nil unless avatar_path.include?("pixabay.com")
        if (avatar_path)
          author.avatar = URI.parse(avatar_path)
        end
        #author_name = author_page.css('#hero h2').try(:first).try(:text).to_s.split("  •  ").first
        author.url = author_url
        author.source_id = high_res_info['user_id'].to_s
      end
      save!
    end

    private

      def get_high_res_info
        @high_res_info ||= (
          uri = URI('https://pixabay.com/api/')
          uri.query = URI.encode_www_form({
            id: source_id,
            response_group: 'high_resolution'
          }.merge(Artifacts::PixabayImage.api_credentials))
          response = JSON.parse(Net::HTTP.get_response(uri).body)
        )
      end

      def get_regular_info
        @regular_info ||= (
          uri = URI('https://pixabay.com/api/')
          args = { id: source_id }.merge(Artifacts::PixabayImage.api_credentials)
          uri.query = URI.encode_www_form(args)
          response = JSON.parse(Net::HTTP.get_response(uri).body)
        )
      end

      # def get_source_tags
      #   get_regular_info['hits'].first['tags'].split(/\s*,\s*/)
      # end
  end
end
