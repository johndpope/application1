module Artifacts
  class UnsplashImage < Image
    class << self
      def list(options = {})
        params = Image::DEFAULTS.merge(options)
        params.symbolize_keys!
        params[:page] = 1 unless params[:page].present?

        images = Unsplash::Photo.search(params[:q], params[:page].to_i, params[:limit].to_i)

        result = { total: images.present? ? 1000000000 : 0 }
        unless options[:show_imported].present?
          imported_source_ids = Artifacts::UnsplashImage.select(:source_id).distinct.pluck(:source_id)
          images.reject! { |item| imported_source_ids.include?(item.id.to_s)}
        end
        unless options[:show_rejected].present?
          images.reject! { |item| options[:rejected_images_ids].include?(item.id.to_s)}
        end
        persisted_images = Artifacts::UnsplashImage.where(source_id: images.map {|photo| photo.id.to_s} )
        result[:items] = images.map do |photo|
          image = persisted_images.select { |img| img.source_id == photo.id.to_s }.first
          image = Artifacts::UnsplashImage.new(source_id: photo.id.to_s) unless image.present?
          image.title = photo.title
          image.url = photo.urls['small']
          image.url_o = photo.urls['raw']
          image.page_url = photo.links['html']
          image.width = photo.width
          image.height = photo.height
          image.description = photo.description.to_s
          image
        end
        result
      end
    end

    def import
      photo = Unsplash::Photo.find(source_id)
      #self.title = photo.title
      self.url = photo.urls['raw']
      self.page_url = photo.links['html']
      self.file = URI.parse(url)
      #add extension if doesn't exist
      unless self.file.nil?
        extension = File.extname(self.file.original_filename)
        if !extension || extension == ''
          mime = self.file.content_type
          ext = Rack::Mime::MIME_TYPES.invert[mime]
          self.file.instance_write :file_name, "#{self.file.original_filename}#{ext}"
        end
      end
      self.license_name = "Public Domain Dedication (CC0)"
      self.license_url = "https://creativecommons.org/publicdomain/zero/1.0/"
      user = photo.user
      if user.present?
        self.author = Artifacts::UnsplashAuthor.where(username: user.username).first_or_create! do |author|
          author.avatar = URI.parse(user.profile_image['large']) if user.profile_image['large'].present?
          author.name = user.name
          author.username = user.username
          author.url = user.links['html']
        end
      end
      save!
    end
  end
end
