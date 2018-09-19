class VideoScript < ActiveRecord::Base
	extend Enumerize
	enumerize :script_status, in:{new:1, in_progress:2, finished:3, approved:4}

	def self.import()
		video_scripts_dir = File.join(Rails.root.join('tmp','video_scripts'))
		html_dir = File.join(video_scripts_dir,'html')
		FileUtils.rm_r video_scripts_dir if Dir.exists? video_scripts_dir
		FileUtils.mkdir_p html_dir	

		system "unzip #{File.join(Rails.root.join('db','video_scripts', 'html.zip'))} -d #{html_dir}"

		Dir.foreach(html_dir) do |dir|
			next if dir == '.' || dir == '..'						
			cur_html_dir = File.join(html_dir, dir)

			Dir.glob(File.join(cur_html_dir, "*.html")) do |html_item|			
				html_doc = Nokogiri::HTML(File.open(html_item))				
				video_script = VideoScript.create({:body=>html_doc.at('body').inner_html})				
				html_doc.css('img').each do |img|
					rich_file = Rich::RichFile.new
					rich_file.simplified_type = 'image'
					rich_file.owner_type = "video_scripts/#{video_script.id}"
					rich_file.owner_id = 0
					rich_file.rich_file = File.open(File.join(cur_html_dir,URI.unescape(img['src'])))										
					rich_file.save					

					img.attributes['src'].value = rich_file.rich_file.url(:original)
				end
				video_script.update({body: html_doc.at('body').inner_html})
			end
		end

		FileUtils.rm_r video_scripts_dir if Dir.exists? video_scripts_dir
	end
end
