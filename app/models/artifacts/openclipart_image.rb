module Artifacts
  class OpenclipartImage < Image
    class << self
      def list(options = {})
        options[:limit] ||= Artifacts::Image::DEFAULTS[:limit]

        uri = URI('https://openclipart.org/search/json/')
        uri.query = URI.encode_www_form({
          query: options[:q],
          page: options[:page],
          amount: options[:limit]
        })

        response = JSON.parse(Net::HTTP.get_response(uri).body)
        if response['msg'] == 'success'
          result = { total: response['info']['results'].to_i }
          unless options[:show_imported].present?
            imported_source_ids = Artifacts::OpenclipartImage.select(:source_id).distinct.pluck(:source_id)
            response['payload'].reject! { |item| imported_source_ids.include?(item['id'].to_s)}
          end
          unless options[:show_rejected].present?
            response['payload'].reject! { |item| options[:rejected_images_ids].include?(item['id'].to_s)}
          end
          persisted_images = Artifacts::OpenclipartImage.where(source_id: response['payload'].map {|photo| photo['id'].to_s} )
          result[:items] = response['payload'].map do |photo|
            image = persisted_images.select { |img| img.source_id == photo['id'].to_s }.first
            image = Artifacts::OpenclipartImage.new(source_id: photo['id'].to_s) unless image.present?
            image.title = photo['title']
            image.source_tag_list = photo['tags'].split(",").map(&:strip)
            image.url = photo['svg']['png_full_lossy']
            image.url_o = photo['svg']['png_2400px']
            image.page_url = photo['detail_link']
            image
          end
          result
        else
          { total: 0, items: [] }
        end
      end
    end

    def import
      super
      item = get_source_info
      if item.present? && item["svg_filesize"] < 1000000
        self.title = item['title']
        self.source_tag_list = item["tags_array"]
        self.license_name = 'Creative Commons Deed CC0'
        self.license_url = 'http://creativecommons.org/publicdomain/zero/1.0/deed.en'
        #self.url = "https://openclipart.org/image/1024px/svg_to_png/#{source_id}/#{URI.escape(title)}.png"
        self.url = URI.encode(item["svg"]["url"])
        self.file = URI.parse(url)
        #self.file_file_name = "#{title}.png"
        self.file_file_name = self.url.split("/").last
        self.page_url = item['detail_link']
        page = Nokogiri::HTML(open("https://openclipart.org/detail/#{source_id}"))
        username = page.css("#viewauthor span[itemprop=name]").first.content
        self.author = Artifacts::OpenclipartAuthor.where(username: username).first_or_create! do |author|
          author_uri = URI.encode("https://openclipart.org/user-detail/#{username}")
          author_page = Nokogiri::HTML(open(author_uri))
          if (img = author_page.css("#user-info img").first)
            avatar_path = URI.encode(img.attr('src'))
            author.avatar = URI.parse("https://openclipart.org#{avatar_path}")
          end
        end
      end
      save!
    end

    private

      def get_source_info
        @source_info ||= (
          uri = URI("https://openclipart.org/search/json/")
          uri.query = URI.encode_www_form({ byids: source_id })
          info = JSON.parse(Net::HTTP.get_response(uri).body)
          info['payload'].first
        )
      end

      def get_source_tags
        get_source_info['tags_array']
      end
  end
end
