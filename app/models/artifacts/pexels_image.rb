module Artifacts
  class PexelsImage < Image
    class << self
      def api_call(params)
        uri = URI.parse('http://api.pexels.com/v1/search')
        uri.query = URI.encode_www_form(params)
        http = Net::HTTP.new(uri.host, uri.port)
        # http.use_ssl = true
        # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        request.add_field("Authorization", CONFIG['pexels']['api_key'])
        response = http.request(request)
        response.body
      end

      def list(options = {})
        params = Image::DEFAULTS.merge(options)
        params.symbolize_keys!

        response = api_call({
          query: params[:q],
          per_page: params[:limit],
          page: params[:page]
        })

        images = JSON.parse(response)

        result = { total: images['total_results'].to_i }
        unless options[:show_imported].present?
          imported_source_ids = Artifacts::PexelsImage.select(:source_id).distinct.pluck(:source_id)
          images['photos'].reject! { |item| imported_source_ids.include?(item['id'].to_s)}
        end
        unless options[:show_rejected].present?
          images['photos'].reject! { |item| options[:rejected_images_ids].include?(item['id'].to_s)}
        end
        persisted_images = Artifacts::PexelsImage.where(source_id: images['photos'].map {|photo| photo['id'].to_s} )
        result[:items] = images['photos'].map do |photo|
          image = persisted_images.select { |img| img.source_id == photo['id'].to_s }.first
          image = Artifacts::PexelsImage.new(source_id: photo['id'].to_s) unless image.present?
          image.title = photo['url'].gsub("https://www.pexels.com/photo/", "").gsub("-#{photo['id']}", "").gsub("-", " ").gsub("/", "").humanize
          image.url = photo['src']['medium']
          image.url_o = photo['src']['original']
          image.width = photo['width']
          image.height = photo['height']
          image.page_url = photo['url']
          image
        end
        result
      end
    end

    def import
      image_page = Nokogiri::HTML(open("https://www.pexels.com/photo/#{self.source_id}"))
      if (image_path = image_page.css(".photo-modal").css("a[data-id]").try(:first).try(:attr, 'href'))
        self.url = image_path
      end
      source_tags = image_page.css("meta[name='keywords']").try(:first).try(:attr, 'content').to_s.split(",").map { |t| t.mb_chars.downcase.to_s.strip }.uniq.reject(&:blank?)
      source_tags.delete("free stock photo")
      self.source_tag_list = source_tags
      self.page_url = image_page.css("link[rel='canonical']").try(:first).try(:attr, 'href').to_s
      self.title = self.page_url.gsub("https://www.pexels.com/photo/", "").gsub("-#{self.source_id}", "").gsub("-", " ").gsub("/", "").humanize
      description_info = image_page.css("meta[name='description']").try(:first).try(:attr, 'content').to_s
      self.description = description_info.include?("One of many great free stock photos from Pexels") ? "" : description_info
      self.file = URI.parse(self.url)
      info = image_page.css('span.icon-list__title').map(&:text)
      self.notes = info.select{|e| e.include?("Software:")}.first.to_s.strip
      location_url = image_page.css("a[data-track-label='location']").try(:first).try(:attr, 'href').to_s.gsub("http://maps.google.com/maps?q=", "")
      if location_url.present?
        coordinates = location_url.split("+")
        self.lat = coordinates[0].to_f
        self.lng = coordinates[1].to_f
      end
      author_name = info.select{|e| e.include?("Photographer:")}.first.to_s.gsub("Photographer: ", "").strip
      if author_name.present?
        self.author = Artifacts::PexelsAuthor.where(name: author_name).first_or_create! do |author|
          author.name = author_name
        end
      end
      self.license_name = "Creative Commons Zero (CC0) license"
      self.license_url = "https://creativecommons.org/publicdomain/zero/1.0/"
      save!
    end
  end
end
