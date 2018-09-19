require 'flickraw'

module Artifacts
  class FlickrImage < Image

    SORTING = %w(date-posted-desc date-posted-asc date-taken-desc date-taken-asc interestingness-desc interestingness-asc relevance)

    DEFAULTS = {
      media: 'photos',
      license: %w(4 5 8 9 10),
      extras: "description,tags,url_o,o_dims"
    }

    after_create do
      self.delay(queue: DelayedJobQueue::UPDATE_GEO_INFO, priority: 2).update_geo_info
    end

    class << self
      def api_call(params)
        uri = URI.parse('https://api.flickr.com/services/rest/')
        uri.query = URI.encode_www_form(params)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        response.body
      end

      def list(options = {})
        params = Image::DEFAULTS.merge(DEFAULTS).merge(options)
        params.symbolize_keys!

        response = api_call({
          method: 'flickr.photos.search',
          api_key: CONFIG['flickr']['api_key'],
          format: 'json',
          nojsoncallback: 1,
          text: params[:q],
          per_page: params[:limit],
          page: params[:page],
          tags: params[:tags],
          license: params[:license].join(','),
          media: params[:media],
          sort: params[:sort],
          user_id: params[:user_id],
          extras: params[:extras]
        })

        images = JSON.parse(response)

        result = { total: images['photos']['total'].to_i }
        unless options[:show_imported].present?
          imported_source_ids = Artifacts::FlickrImage.select(:source_id).distinct.pluck(:source_id)
          images['photos']['photo'].reject! { |item| imported_source_ids.include?(item['id'].to_s)}
        end
        unless options[:show_rejected].present?
          images['photos']['photo'].reject! { |item| options[:rejected_images_ids].include?(item['id'].to_s)}
        end
        persisted_images = Artifacts::FlickrImage.where(source_id: images['photos']['photo'].map {|photo| photo['id'].to_s} )
        result[:items] = images['photos']['photo'].map do |photo|
          image = persisted_images.select { |img| img.source_id == photo['id'].to_s }.first
          image = Artifacts::FlickrImage.new(source_id: photo['id'].to_s) unless image.present?
          image.title = photo['title']
          image.source_tag_list = photo['tags'].to_s.split(' ').map { |t| t.mb_chars.downcase.to_s }.uniq.reject(&:blank?)
          image.description = photo['description']['_content']
          image.url = "https://farm#{photo['farm']}.staticflickr.com/#{photo['server']}/#{photo['id']}_#{photo['secret']}.jpg"
          image.url_o = photo['url_o']
          image.page_url = "https://www.flickr.com/photos/#{photo['owner']}/#{photo['id']}"
          image.height = photo['o_height'].to_i
          image.width = photo['o_width'].to_i
          image
        end
        result
      end

      def licenses
        @@licenses ||= (
          response = api_call({
            method: 'flickr.photos.licenses.getInfo',
            api_key: CONFIG['flickr']['api_key'],
            format: 'json',
            nojsoncallback: 1
          })
          JSON.parse(response)['licenses']['license']
        )
      end
    end

    def update_geo_info
      begin
        location = flickr.photos.geo.getLocation(photo_id: self.source_id)
        self.lat = location['location']['latitude'].to_f
        self.lng = location['location']['longitude'].to_f
        self.save
      rescue
      end
    end

    def update_description
      begin
        info = get_source_info
        self.description = info['description']['_content'].to_s
      rescue
        self.description = 'error'
      end
      self.save
    end

    def import
      super
      info = get_source_info
      owner = info['owner']
      sizes = get_source_sizes
      self.title = info['title']['_content']
      self.description = info['description']['_content'].to_s
      self.source_tag_list = get_source_tags
      self.url = sizes['size'].last['source']
      self.license_code = info['license']
      license = FlickrImage.licenses.select { |l| l['id'] == license_code }.first
      self.license_name = license['name']
      self.license_url = license['url']
      self.file = URI.parse(url)
      self.page_url = "https://www.flickr.com/photos/#{owner['nsid']}/#{source_id}"
      self.author = Artifacts::FlickrAuthor.where(source_id: owner['nsid']).first_or_create! do |author|
        author.username = owner['username']
        author.name = owner['realname']
        author.url = "https://www.flickr.com/people/#{owner['nsid']}"
        author_page = Nokogiri::HTML(open(author.url))
        if (avatar_url = author_page.css('img.sn-avatar-ico').first.attr('src'))
          author.avatar = URI.parse(avatar_url)
        end
      end
      save!
    end

    def get_original_size
      get_source_sizes['size'].select{|e| e['label'] == 'Original'}.first
    end

    def get_source_sizes
      @source_sizes ||= (
        response = Artifacts::FlickrImage.api_call({
          method: 'flickr.photos.getSizes',
          api_key: CONFIG['flickr']['api_key'],
          format: 'json',
          nojsoncallback: 1,
          photo_id: source_id
        })
        JSON.parse(response)['sizes']
      )
    end

    private

      def get_source_info
        @source_info ||= (
          response = Artifacts::FlickrImage.api_call({
            method: 'flickr.photos.getInfo',
            api_key: CONFIG['flickr']['api_key'],
            format: 'json',
            nojsoncallback: 1,
            photo_id: source_id
          })
          JSON.parse(response)['photo']
        )
      end

      def get_source_tags
        get_source_info['tags']['tag'].map { |t| t['raw'].mb_chars.downcase.to_s }.uniq.reject(&:blank?)
      end
  end
end
