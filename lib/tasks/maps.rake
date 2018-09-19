namespace :maps do
  desc 'Refactor state maps'
  task county_ids: :environment do
    states = Geobase::Country.find_by(code: 'US').regions.where(level: 1).pluck('code')
    count = 0
    states.each do |state|
      if File.exists?(path = "#{Rails.root}/app/assets/javascripts/jvectormap/#{state.downcase}-lcc-en.js")
        count += 1
        puts path
        text = File.read(path).scan(/lcc_en',(.+)\);/)[0][0]
        data = eval(text.gsub(/": /, '" => '))
        data['paths'] = Hash[data['paths'].map { |k, v| ["#{state} #{v['name']}", v] }]
        File.write(
          "#{Rails.root}/app/assets/javascripts/maps/#{state.downcase}-lcc-en.js",
          "jQuery.fn.vectorMap('addMap', '#{state.downcase}_lcc_en', #{data.to_json});"
        )
      end
    end
    puts count
  end
end
