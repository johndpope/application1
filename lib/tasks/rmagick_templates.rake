namespace :rmagick_templates do
    task :still_image, [:template_name, :compilation_size] => :environment do |t, args|
        require "#{Rails.root}/app/helpers/rmagick_templates_helper"
        include RmagickTemplatesHelper

        args.with_defaults(compilation_size: 10)

        make_still_image(args.template_name, args.compilation_size)
    end

    task :random_image_set, [:image_tags, :prefix, :extention, :dimensions, :image_count] => :environment do |t, args|
      require "#{Rails.root}/app/helpers/rmagick_templates_helper"
      include RmagickTemplatesHelper      
      make_random_image_set(args.image_tags.split('|'), args.prefix, args.extention, args.dimensions, args.image_count)
    end
end
