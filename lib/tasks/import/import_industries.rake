namespace :db do
  namespace :seed do
    task :import_industries => :environment do
      puts "import industries task started"
      if Industry.all.size == 0
        CSV.foreach('db/industries.csv',{:headers=>false,:col_sep=>';'}) do |row|
          Industry.create(code: row[0], name: row[1])
        end
      end
      puts "import industries task finished"
    end
    task :fix_industry_relationships => :environment do
      puts "Fix industry relationships task started"
      Industry.all.each do |i|
        if i.code.size > 2
          parent_code = i.code[0...i.code.size-1]
          if %(31 32 33).include?(parent_code)
            i.parent_id = Industry.find_by_code("31").id
          elsif %(44 45).include?(parent_code)
            i.parent_id = Industry.find_by_code("44").id
          elsif %(48 49).include?(parent_code)
            i.parent_id = Industry.find_by_code("48").id
          else
            i.parent_id = Industry.find_by_code(parent_code).try(:id)
          end
          i.save
        end
      end
      puts "Fix industry relationships task finished"
    end
  end
end
