module Artifacts
  class IconfinderImage < Image
    MAX_LIMIT = 100
    DEFAULTS = {
      license: 'commercial-nonattribution'
    }
    LICENSES = %w(none commercial commercial-nonattribution)

    class << self
      def list(options = {})
        params = Image::DEFAULTS.merge(DEFAULTS).merge(options)
        params.symbolize_keys!
        limit = params[:limit].to_i
        page = (params[:page] || 1).to_i

        result = { items: [] }
        remainder = limit
        offset = limit * (page - 1)
        while remainder > 0
          count = [remainder, MAX_LIMIT].min

          uri = URI('https://api.iconfinder.com/v2/icons/search')
          uri.query = URI.encode_www_form({
            client_id: CONFIG['iconfinder']['client_id'],
            query: params[:q],
            premium: 0,
            offset: offset,
            license: params[:license],
            count: count
          })

          response = JSON.parse(Net::HTTP.get_response(uri).body)
          result[:total] ||= response['total_count'].to_i
          unless options[:show_imported].present?
            imported_source_ids = Artifacts::IconfinderImage.select(:source_id).distinct.pluck(:source_id)
            response['icons'].delete_if { |item| imported_source_ids.include?(item['icon_id'].to_s)}
          end
          unless options[:show_rejected].present?
            response['icons'].delete_if { |item| options[:rejected_images_ids].include?(item['icon_id'].to_s)}
          end
          persisted_images = Artifacts::IconfinderImage.where(source_id: response['icons'].map {|icon| icon['icon_id'].to_s} )
          response['icons'].each do |icon|
            image = persisted_images.select { |img| img.source_id == icon['icon_id'].to_s }.first
            image = Artifacts::IconfinderImage.new(source_id: icon['icon_id'].to_s) unless image.present?
            image.title = icon['tags'].map(&:titleize).join(', ')
            image.source_tag_list = icon['tags']
            image.url = icon['raster_sizes'].last['formats'].first['preview_url']
            image.url_o = icon['raster_sizes'].last['formats'].first['preview_url']
            image.page_url = "https://www.iconfinder.com/icons/#{icon['icon_id']}"
            result[:items] << image
          end

          remainder -= count
          offset += count
        end
        result
      end
    end

    def import
      super
      info = get_source_info
      format = info['raster_sizes'].last['formats'].first
      path = format['download_url']
      license = info['iconset']['license']
      self.license_name = license['name']
      self.license_code = license['license_id']
      self.license_url = license['url']
      self.title = get_source_tags.map(&:titleize).join(', ')
      self.source_tag_list = get_source_tags
      self.url = "https://api.iconfinder.com/v2#{path}"
      self.file = URI.parse(url)
      self.file_file_name = "#{source_id}.#{format['format']}"
      self.page_url = "https://www.iconfinder.com/icons/#{source_id}"
      author_info = info['iconset']['author']
      self.author = Artifacts::IconfinderAuthor.where(source_id: author_info['user_id'].to_s).first_or_create! do |author|
        author.username = author_info['username']
        author.name = author_info['name']
        author.url = "https://www.iconfinder.com/#{author.username}"
        author_page = Nokogiri::HTML(open(author.url))
        if (img = author_page.css('.user-image img').first)
          avatar_url = img.attr('src')
          author.avatar = URI.parse(avatar_url)
          if author.avatar_content_type
            extension = author.avatar_content_type.split('/').last
            author.avatar_file_name = "#{author.username}.#{extension}"
          end
        end
      end
      save!
    end

    private

      def get_source_info
        @source_info ||= (
          uri = URI("https://api.iconfinder.com/v2/icons/#{source_id}")
          JSON.parse(Net::HTTP.get_response(uri).body)
        )
      end

      def get_source_tags
        get_source_info['tags']
      end
  end
end
