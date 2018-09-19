namespace :db do
  namespace :seed do
    task :import_artifacts_image_categories => :environment do
      puts "import artifcat images categories"

      CSV.foreach('db/artifacts_image_categories.csv', {:headers => false, :col_sep => ';'}) do |row|
        puts row.to_s
        tags_array = row.first.split(",").map(&:strip).reject(&:empty?)
        subcategory_name = row[1].strip
        category_name = row[2].strip

        category = Artifacts::ImageCategory.where("parent_id IS NULL and LOWER(name) = ?", category_name.downcase).first
        subcategory = Artifacts::ImageCategory.where("parent_id = ? and LOWER(name) = ?", category.id, subcategory_name.downcase).first

        tags_array.each do |tag|
          puts "tag: #{tag}"
          Artifacts::Image.with_tags([tag]).each do |image|
            image_categories = (image.image_categories + [subcategory]).compact.uniq
            image.update_attributes(:image_categories => image_categories)
          end
        end

      end
      puts "import categories to artifacts images task finished"
    end
  end
end
