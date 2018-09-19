namespace :db do
	namespace :seed do
	  task :import_text_chunks => :environment do
			file_names = Dir.entries("#{Rails.root}/db/text_chunks/").delete_if {|f| [".",".."].include? f }
	    puts "import text chunks task started"
			file_names.each do |file_name|
				chunk_type = file_name.sub(".csv", "")
				CSV.foreach("db/text_chunks/#{file_name}",{:headers=>false, :col_sep=>";", :quote_char=>"\""}) do |row|
					TextChunk.create(chunk_type: chunk_type, value: row[0].strip)
				end
			end
	    puts "import text chunks task finished"
	  end
	end
end
