namespace :artifacts do
  namespace :images do
    desc 'Identify images\' dimensios and store them in the database'
    task store_dimensions: :environment do
      Artifacts::Image.unscoped.where.not(file_file_name: nil).find_in_batches(batch_size: 100) do |batch|
        batch.each do |image|
          begin
            geometry = Paperclip::Geometry.from_file(image.file)
            image.assign_attributes(
              width: geometry.width.to_i,
              height: geometry.height.to_i
            )
          rescue Exception => e
            Rails.logger.error e.message
          end
        end
        ActiveRecord::Base.transaction { batch.each { |image| image.save! } }
      end
    end

    desc 'Fix missing tags'
    task fix_missing_tags: :environment do
      %w(Openclipart Iconfinder Pixabay Flickr).each do |type|
        "Artifacts::#{type}Image".constantize.where.not(file_file_name: nil).find_each do |image|
          image.instance_eval do
            begin
              self.source_tag_list = get_source_tags
              save!
            rescue
              Rails.logger.error "Failed to fix missing source tags for #{type} image with ID #{source_id}"
            end
          end
        end
      end
    end

    desc 'Recreate jobs to use Artifacts::ImageImportJob instead of Artifacts::ImageService#import'
    task rebuild_image_import_jobs: :environment do
      Delayed::Job.where('handler like ?', '%Artifacts::ImagesService%').delete_all
      Artifacts::Image.unscoped.where(file_file_name: nil).find_in_batches do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |image|
            Delayed::Job.enqueue Artifacts::ImageImportJob.new(image.type, image.id),
							queue: DelayedJobQueue::ARTIFACTS_IMAGE_IMPORT,
							priority: DelayedJobPriority::LOW
          end
        end
      end
    end

    task :import_from_flickr, [:search_query, :user_id, :license, :tags] => :environment do |t,args|
        args.with_defaults(:license => '4|5|8|9|10')

        options = {limit: 100}
        options[:q] = args.search_query
        options[:license] = args.license.split('|') unless args.license.blank?
        options[:user_id] = args.user_id unless args.user_id.blank?

        api_response = Artifacts::FlickrImage.list(options)
        total = api_response[:total] / options[:limit] + (api_response[:total] % options[:limit] > 0 ? 1 : 0)
        cur_page = 1

        loop do
            info_str = []
            info_str << "query: " + args.search_query unless args.search_query.blank?
            info_str << "user: #{args.user_id}" unless args.user_id.blank?
            info_str << "page: #{cur_page}"
            puts  info_str.join ', '

            api_response[:items].each do |fi|
                fi.tag_list = args.tags.gsub('|',',')
                ActiveRecord::Base.transaction do
                    fi.save!
                    Artifacts::ImagesService.delay(queue: DelayedJobQueue::ARTIFACTS_IMAGE_IMPORT).import("FlickrImage", fi.id)
                end
            end
            cur_page += 1
            break if cur_page > total
            api_response = Artifacts::FlickrImage.list(options.merge({page: cur_page}))
        end
    end

    task remove_inappropriate_social_channel_art: :environment do
        sca = ActsAsTaggableOn::Tag.find_by(name: 'social_channel_art')
        taggings = ActsAsTaggableOn::Tagging.where(tag: sca, taggable_type: 'Artifacts::Image')
        Artifacts::FlickrImage.where(id: taggings.select('taggable_id')).where('(width::float / height::float) not between 1.33 and 1.77 OR width < 1500').delete_all
        nil
    end

    #temporary task to import picjumbo images
    task import_picjumbo_images: :environment do
        PICJUMBO_DIR = "/home/broadcaster/picjumbo"

        require 'open-uri'
        puts "importing picjumbo images .."

        Dir.glob(File.join(PICJUMBO_DIR,'*.jpg')).each do |img|
            ActiveRecord::Base.transaction do
                picjumbo_image = Artifacts::PicjumboImage.new
                picjumbo_image.file = open(img)
                picjumbo_image.title = File.basename(img,File.extname(img)).titleize
                picjumbo_image.tag_list = 'social_channel_art'
                picjumbo_image.save!
                puts "#{File.basename img} imported"
            end
        end
    end

    #rake artifacts:create_gravity_cropping_variations[12345]
    task :create_gravity_cropping_variations, [:image_id] => :environment do |t, args|
      image = Artifacts::Image.find(args[:image_id])

      img_ext = File.extname image.file.path
  		img_basename = File.basename(image.file.path).gsub(img_ext, '')
  		img = Magick::Image.read(image.file.path).first

  		crop_side_1 = 600
  		crop_side_2 = 300

  		crop_side_1 = img.columns/2 unless img.columns > 1024
  		crop_side_2 = img.rows/2 unless img.rows > 768

  		if(crop_side_1 < crop_side_2)
  			tmp_side = crop_side_1
  			crop_side_1 = crop_side_2
  			crop_side_2 = tmp_side
  		end

      output = File.join('/tmp', "#{img_basename}-aspect-crop-square#{img_ext}")

    end

    task :create_aspect_cropping_variations, [:tags] => :environment do |t, args|
      tag_list = args.tags.split('|')
      images = Artifacts::Image.downloaded.with_tags tag_list
      ActiveRecord::Base.transaction do
        images.each do |i|
          i.delay(queue: DelayedJobQueue::ARTIFACTS_IMAGE_ASCPECT_CROPPING_VARIATIONS).make_aspect_cropping_variations if i.image_aspect_cropping_variations.blank?
        end
      end
    end
  end
end
