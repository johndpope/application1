namespace :templates do
  namespace :image_template do

    # Google Plus
    GP_WIDTH = 1600
    GP_HEIGHT = 900
    # Thumbnail
    T_WIDTH = 1280
    T_HEIGHT = 720
    # YouTube channel art
    YCA_WIDTH = 2560
    YCA_HEIGHT = 1440
    TEMPLATES_PATH = "#{Rails.root}/lib/rmagick_templates/lib/rmagick_templates/svg_templates"
    SERVER_TEMPLATES_PATH = "#{Rails.root}/public/system/templates/image_templates/000/000"

    desc "Parse SVG-template"
    task :add_templates_from_dir => :environment do

      svg_path = File.join("#{Rails.root}","lib/rmagick_templates/lib/rmagick_templates/svg_templates")

      arr = Dir.entries(svg_path)
      arr.delete("."){"not found"}
      arr.delete(".."){"not found"}
      arr = arr.sort        #формирование массива с названиями дирректорий содержащих svg

      arr.each do |i|
        path = File.join(TEMPLATES_PATH, "#{i}", "tmpl.svg" )
        puts "#{i} :\n"

        ar = Templates::ImageTemplate.where(:name => i.to_s)  #array of items
        if ar.any?  #если есть с таким названием template в БД
          if File.exist? path #если существует такой файл на диске, парсить его
              svg = Nokogiri::XML(File.open(path))

              svg.css("image").each do |image|
                id = ar[0].id
                img_name = image[:id]
                width = image[:width]
                height = image[:height]

                unless (img_name == "background_image0" || img_name == "background_image1")
                  puts "IMG: id: #{id}/ img_name: #{img_name} /width: #{width} /height: #{height} \n"
                  Templates::ImageTemplateImage.new(:image_template_id => id, :name => img_name, :width => width, :height => height).save
                end

              end

              svg.css("text").each do |text|
                txt_image_template_id = ar[0].id
                txt_name = text[:id]
                puts "TXT: template_id: #{txt_image_template_id} / txt_name: #{txt_name} \n"
                Templates::ImageTemplateText.new(:image_template_id => txt_image_template_id, :name => txt_name).save
              end

          else
            puts "File in #{path}, not exist"
          end
        else
          puts "in BD not so templates"
        end
      end

    end

    # добавить изображения и тексты к шаблонам из БД
    desc "IMAGES/TEXTS, add to exist template"
    task :add_templates_txt_img => :environment do
      templates = Templates::ImageTemplate.all.order("name ASC")

      templates.each do |t|
        folder = t.name
        # pth = File.join(TEMPLATES_PATH, "#{folder}", "tmpl.svg" )
        pth = File.join(SERVER_TEMPLATES_PATH, "#{t.id}" , "original/tmpl.svg")
        puts "PATH: #{pth}"
        image_template_id = t.id

        if File.exist? pth
          svg = Nokogiri::XML(File.open(pth))
          svg.css("image").each do |img|

            img_name = img[:id]
            width = img[:width]
            height = img[:height]

            unless (img_name == "background_image0" || img_name == "background_image1")
              if width.to_s == "100%"
                if folder.include? "youtube"
                  width = YCA_WIDTH
                elsif folder.include? "thumbnail"
                  width = T_WIDTH
                elsif folder.include? "google"
                  width = GP_WIDTH
                end
              end

              if height.to_s == "100%"
                if folder.include? "youtube"
                  height = YCA_HEIGHT
                elsif folder.include? "thumbnail"
                  height = T_HEIGHT
                elsif folder.include? "google"
                  height = GP_HEIGHT
                end
              end

              result_img = Templates::ImageTemplateImage.new(:image_template_id => image_template_id, :name => img_name, :width => width, :height => height).save
              puts "#{image_template_id} IMG:#{img_name} width: #{width} height: #{height}| #{result_img}"

              svg.css("text").each do |txt|
                txt_name = txt[:id]
                result_txt = Templates::ImageTemplateText.new(:image_template_id => image_template_id, :name => txt_name).save
                puts "#{image_template_id} TXT:#{txt_name}| #{result_txt}"
              end
                puts "\n"
            end
          end
        else
          puts "SVG file not exist by path: #{pth}"
        end
      end
    end

# ----------------------------------------------------------------------------------------------------------------
    desc "EXPORT templates to DB, by scan folder"
    task :add_templates,[:from, :to] => :environment do |t, args|

      if File.directory?(TEMPLATES_PATH)
        arr = Dir.entries(TEMPLATES_PATH)
        arr.delete("."){"not found"}
        arr.delete(".."){"not found"}
        arr = arr.sort        #формирование массива с названиями дирректорий содержащих svg
      else
        arr = []
        puts "directory is not found"
      end

      unless args[:from].to_i == 0
        from = args[:from].to_i
      else
        from = 0
      end

      unless args[:to].to_i == 0
        to = args[:to].to_i
      else
        to = arr.length
      end

      arr[from..to].each do |tmpl|
        path_template_folder = File.join(TEMPLATES_PATH, "#{tmpl}")
        files = Dir.entries(path_template_folder)
        files.delete("..")
        files.delete(".")

        unless files[0] == nil
          path_svg = File.join(path_template_folder, files[0])
        else
          path_svg = nil
        end

        unless files[1] == nil
          path_sample = File.join(path_template_folder, files[1])
        else
          path_sample = nil
        end

        type = tmpl.split("_")[0]
        reg = Regexp.new(/\d/)
        type = type.gsub(reg,"")

        Templates::ImageTemplate::TYPES.each do |t|
          if t.to_s.downcase.include?(type)
            type = t
          end
        end

        qw = Templates::ImageTemplate.new(:name => tmpl.to_s, :is_active => true, :type => type)

        if File.exists?(path_sample.to_s)
          qw.sample = open(path_sample.to_s)
        end

        if File.exists?(path_svg.to_s)
          qw.svg = open(path_svg.to_s)
        end

        puts "#{tmpl} => #{qw.save}"
        puts "ID: #{qw.id}"

      end
      puts "all #{to - from} templates"
    end

    # удалить из БД (шаблонов несоответствующих шаблонам в папке)
    desc "REMOVE OTHER templates from DB"
    task :remove_other_templates => :environment do
      arr = Dir.entries(TEMPLATES_PATH)
      arr.delete("."){"not found"}
      arr.delete(".."){"not found"}
      arr = arr.sort

      allTemplates = Templates::ImageTemplate.all
      allTemplates.each do |item|
        unless arr.include? item.name   #если в базе есть шаблон которого нет в папке -> удалить его
          Templates::ImageTemplate.where(:name => item.name.to_s).destroy_all
          puts "#{item.name} deleted from DB"
        end
      end
    end

    # удаление всех шаблонов из БД
    desc "REMOVE ALL templates from DB"
    task :remove_all_templates => :environment do
      templates = Templates::ImageTemplate.all
        templates.each do |item|
          Templates::ImageTemplate.where(:name => item.name.to_s).destroy_all
          puts "#{item.name} was deleted"
        end
      puts "All templates was deleted"
    end

  end
end
