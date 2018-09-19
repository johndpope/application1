# encoding 'utf-8'
namespace :geonames do

  @error_log ||= Logger.new("#{Rails.root}/log/geonames_errors.log")
  @log ||= Logger.new("#{Rails.root}/log/geonames.log")
  @localities_country_list = Dir.entries('public/system/geonames/localities')
                                .reject { |f| File.directory? f }
                                .map! { |item| item[0..-5] }
                                .sort
  @zips_country_list = Dir.entries('public/system/geonames/zips')
                          .reject { |f| File.directory? f }
                          .map! { |item| item[0..-5] }
                          .sort

  desc 'Import countries information from geonames'
  task :countries, %i[code] => :environment do |_t, args|
    if args[:code].nil?
      @localities_country_list.each do |code|
        puts code
        single_country(code)
      end
    else
      single_country(args[:code])
    end
  end

  desc 'Makes fake country from existing country with CODE by adding SUFFIX'
  task :fake_country, %i[code suffix] => :environment do |_t, args|
    @log.info("Making fake country from #{args[:code]}-country" +
              " with suffix '#{args[:suffix]}'")
    if args[:suffix].nil?
      @log.info('Suffix must NOT be nil')
      exit
    end
    real_country = Geobase::Country.where(code: args[:code]).first
    if real_country.nil?
      @log.info("Country with code #{args[:code]} not exists")
      exit
    end
    fake_country = real_country.dup
    fake_country.code = fake_country.code + args[:suffix]
    fake_country.name = fake_country.name + args[:suffix]
    fake_country.save
  end

  desc 'Imports administrative hierarchy from Geonames for country with CODE'
  task :regions, %i[code] => :environment do |_t, args|
    country_list = @localities_country_list - %w[US MX CA]
    if args[:code].nil?
      country_list.each do |code|
      puts code
      single_country_regions(code)
      end
    else
      single_country_regions(args[:code])
    end
  end

  desc 'Imports localities from Geonames for country with CODE'
  task :localities, %i[code] => :environment do |_t, args|
    country_list = @localities_country_list - %w[US MX CA]
    if args[:code].nil?
      country_list.each do |code|
        puts code
        single_country_localities(code)
      end
    else
      single_country_localities(args[:code])
    end
  end

  desc 'Imports zip-codes from Geonames for country with CODE'
  task :zips, %i[code] => :environment do |_t, args|
    country_list = @zips_country_list - %w[US MX CA]
    if args[:code].nil?
      country_list.each do |code|
        puts code
        single_country_zips(code)
      end
    else
      single_country_zips(args[:code])
    end
  end

  desc 'Temporary task for testing'
  task :test, %i[code mode] => :environment do |_t, args|

  end

  def single_country(code)
    username = 'sidlab'
    country_status = check_country(code)
    if country_status[:updated]
      @log.info("Data for #{code} already updated")
    else
      @log.info("Updating geobase_countries table for #{code}")
      data = get_country_json(code, username)
      country_update(code, data)
    end
  end

  def single_country_regions(code)
    @log.info("Import regions for #{code} country...")
    regions_filename = "public/system/geonames/regions/#{code}.csv"
    @country_id = Geobase::Country.where(code: code).first.id
    unless File.file?(regions_filename)
      CSV.open(regions_filename, 'w', col_sep: "\t") do |temp|
        filename = "public/system/geonames/localities/#{code}.txt"
        csv_file_parse(filename, code) do
          temp << @row  if @row[6] == 'A'
        end
      end
      @log.info("Import regions for #{code} country completed")
    end

    filename = regions_filename
    puts "\033[0;31mLevel 1:\033[0m"
    csv_file_parse(filename, code) do
      if @row[7] == 'ADM1' && !junk_cell(@row[10]) && junk_cell(@row[11]) &&
         junk_cell(@row[12]) && junk_cell(@row[13])
        region_add(1, nil)
      end
    end

    puts "\033[0;31mLevel 2:\033[0m"
    csv_file_parse(filename, code) do
      if (@row[7] == 'ADM2' || @row[7] == 'ADMD' || @row[7] == 'ADMDH') &&
         (!junk_cell(@row[10]) && !junk_cell(@row[11]) &&
         junk_cell(@row[12]) && junk_cell(@row[13]))

        parent_id = Geobase::Region.where(code: @row[10], level: 1).first.id
        region_add(2, parent_id)
      end
    end

    puts "\033[0;31mLevel 3:\033[0m"
    csv_file_parse(filename, code) do
      if (@row[7] == 'ADM3' || @row[7] == 'ADMD' || @row[7] == 'ADMDH') &&
         (!junk_cell(@row[10]) && !junk_cell(@row[12]) && junk_cell(@row[13]))

        parent_id = nil
        begin
          parent_id = Geobase::Region.where(code: @row[11], level: 2).first.id
        rescue NoMethodError
          begin
            @error_log.info("Region #{@row[2]} has unrecognizable " +
                                "level 2 code: #{@row[11]}")
            parent_id = Geobase::Region.where(code: @row[10], level: 1).first.id
          rescue NoMethodError
            @error_log.info("Region #{@row[2]} has unrecognizable " +
                                "level 1 code: #{@row[10]}")
          end
        end
        region_add(3, parent_id)
      end
    end

    puts "\033[0;31mLevel 4:\033[0m"
    csv_file_parse(filename, code) do
      if (@row[7] == 'ADM4' || @row[7] == 'ADMD' || @row[7] == 'ADMDH') &&
          (!junk_cell(@row[10]) && !junk_cell(@row[13]))

        parent_id = nil
        begin
          parent_id = Geobase::Region.where(code: @row[12], level: 3).first.id
        rescue NoMethodError
          @error_log.info("Region #{@row[2]} has unrecognizable " +
                              "level 3 code: #{@row[12]}")
          begin
            parent_id = Geobase::Region.where(code: @row[11], level: 2).first.id
          rescue NoMethodError
            begin
              @error_log.info("Region #{@row[2]} has unrecognizable " +
                                  "level 2 code: #{@row[11]}")
              parent_id = Geobase::Region.where(code: @row[10], level: 1).first.id
            rescue NoMethodError
              @error_log.info("Region #{@row[2]} has unrecognizable " +
                                  "level 1 code: #{@row[10]}")
            end
          end
        end
        region_add(4, parent_id)
      end
    end

    puts "\033[0;31mLevel 5:\033[0m"
    csv_file_parse(filename, code) do
      if (@row[7] == 'ADM5' || @row[7] == 'ADMD' || @row[7] == 'ADMDH') &&
          (!junk_cell(@row[10]))

        parent_id = nil
        begin
          parent_id = Geobase::Region.where(code: @row[13], level: 4).first.id
        rescue NoMethodError
          @error_log.info("Region #{@row[2]} has unrecognizable " +
                              "level 4 code: #{@row[13]}")
          begin
            parent_id = Geobase::Region.where(code: @row[12], level: 3).first.id
          rescue NoMethodError
            @error_log.info("Region #{@row[2]} has unrecognizable " +
                                "level 3 code: #{@row[12]}")
            begin
              parent_id = Geobase::Region.where(code: @row[11], level: 2).first.id
            rescue NoMethodError
              begin
                @error_log.info("Region #{@row[2]} has unrecognizable " +
                                    "level 2 code: #{@row[11]}")
                parent_id = Geobase::Region.where(code: @row[10], level: 1).first.id
              rescue NoMethodError
                @error_log.info("Region #{@row[2]} has unrecognizable " +
                                    "level 1 code: #{@row[10]}")
              end
            end
          end
        end
        region_add(5, parent_id)
      end
    end
  end

  def single_country_localities(code)
    @log.info("Import localities for #{code} country...")
    @country_id = Geobase::Country.where(code: code).first.id
    filename = "public/system/geonames/localities/#{code}.txt"
    csv_file_parse(filename, code) do
      locality_add if @row[6] == 'P' && %w[PPLX PPLH].exclude?(@row[7])
    end
    @log.info("Import localities for #{code} country completed")
  end

  def single_country_zips(code)
    @log.info("Import zip-codes for #{code} country...")
    @country_id = Geobase::Country.where(code: code).first.id
    filename = "public/system/geonames/zips/#{code}.txt"
    csv_file_parse(filename, code) do
      @region_ids = []
      3.times do |i|
        region = Geobase::Region.where(code: @row[4 + i * 2],
                                       country_id: @country_id).first
        region.nil? ? @region_ids.push(nil) : @region_ids.push(region.id)
      end
      zip_id = zip_add
      locality_id = locality_id_detect

      locality_zip_add(zip_id, locality_id) if zip_id && locality_id
    end
    @log.info("Import zip-codes for #{code} country complete")
  end

  def get_country_json(code, username, update: false)
    if File.file?("public/system/geonames/jsons/#{code}.json") && !update
      @log.info("Getting data for #{code} from #{code}.json file")
      JSON.parse(File.read("public/system/geonames/jsons/#{code}.json"))
    else
      url = 'http://api.geonames.org/countryInfoJSON?lang=en&country=' +
            code + '&username=' + username
      uri = URI(url)
      response = Net::HTTP.get(uri)
      File.open("public/system/geonames/jsons/#{code}.json", 'w:UTF-8') do |file|
        file.write(response.force_encoding('ISO-8859-1').encode('UTF-8'))
      end
      @log.info("Getting data for #{code} from Geonames API")
      JSON.parse(response.force_encoding('ISO-8859-1').encode('UTF-8'))
    end
  end

  def check_country(code)
    country = Geobase::Country.where(code: code).first
    !country ? { new: true, updated: false } : { new: false, updated: !country.geoname_id.nil? }
  end

  def country_update(code, data)
    begin
      country = Geobase::Country.where(code: code).first_or_initialize
      country.code = data['geonames'][0]['countryCode']
      country.name = data['geonames'][0]['countryName']
      country.geoname_id = data['geonames'][0]['geonameId']
      country.continent = data['geonames'][0]['continent']
      country.capital = data['geonames'][0]['capital']
      country.languages = data['geonames'][0]['languages']
      country.south = data['geonames'][0]['south']
      country.isoAlpha3 = data['geonames'][0]['isoAlpha3']
      country.north = data['geonames'][0]['north']
      country.fipsCode = data['geonames'][0]['fipsCode']
      country.population = data['geonames'][0]['population']
      country.east = data['geonames'][0]['east']
      country.isoNumeric = data['geonames'][0]['isoNumeric']
      country.areaInSqKm = data['geonames'][0]['areaInSqKm']
      country.west = data['geonames'][0]['west']
      country.continentName = data['geonames'][0]['continentName']
      country.currencyCode = data['geonames'][0]['currencyCode']
      country.save
    rescue NoMethodError
      puts "\033[0;31mError!\033[0m See error log"
      @error_log.info(code)
      @error_log.info(data['status']['message'])
      @error_log.info("Don't forget to delete file #{code}.json before repeating")
    end
  end

  def region_add(level, parent_id)
    region = Geobase::Region.where(code: @row[10 + level - 1].to_s, country_id: @country_id).first
    return false unless region.nil?
    region = Geobase::Region.new
    region.code = @row[10 + level - 1]
    region.name = @row[2]
    region.level = level
    region.country_id = @country_id
    region.parent_id = parent_id
    region.population = @row[14]
    region.geoname_id = @row[0]
    region.name_original = @row[1]
    region.name_alternatives = @row[3]
    region.save
  end

  def locality_add
    locality = Geobase::Locality.where(geoname_id: @row[0]).first
    return false unless locality.nil?
    ids = get_region_ids([@row[10], @row[11], @row[12], @row[13]])
    locality = Geobase::Locality.new
    locality.primary_region_id = ids[0]
    locality.secondary_region_id = ids[1]
    locality.ternary_region_id = ids[2]
    locality.quaternary_region_id = ids[3]
    locality.name = @row[2]
    locality.name_original = @row[1]
    locality.name_alternatives = @row[3]
    locality.population = @row[14]
    locality.geonames_locality_type = @row[7]
    locality.locality_type = 1 if %w[PPL PPLC].include?(@row[7])
    locality.geoname_id = @row[0]
    locality.latitude = @row[4]
    locality.longitude = @row[5]
    locality.save
  end

  def zip_add
    zip = Geobase::ZipCode.where(code: @row[1],
                                 primary_region_id: @region_ids[0]).first
    return false unless zip.nil?
    zip = Geobase::ZipCode.new
    zip.code = @row[1]
    zip.primary_region_id = @region_ids[0]
    zip.secondary_region_id = @region_ids[1]
    zip.ternary_region_id = @region_ids[2]
    zip.latitude = @row[9]
    zip.longitude = @row[10]
    zip.save
    zip.id
  end

  def locality_zip_add(zip_id, locality_id)
    locality_zip = Geobase::LocalitiesZipCode
                   .where(zip_code_id: zip_id, locality_id: locality_id)
                   .first
    return false unless locality_zip.nil?
    locality_zip = Geobase::LocalitiesZipCode.new
    locality_zip.zip_code_id = zip_id
    locality_zip.locality_id = locality_id
    locality_zip.save
  end

  def locality_id_detect
    localities = Geobase::Locality.where('name = ? or name_original = ?' +
                                         ' or name_alternatives like ?',
                                         @row[2], @row[2], "%#{@row[2]}%").all
    localities.each do |locality|
      localities.delete(locality) if locality.country.id != @country_id
      localities.delete(locality) if locality.primary_region_id != @region_ids[0]
      localities.delete(locality) if locality.secondary_region_id != @region_ids[1]
      localities.delete(locality) if locality.ternary_region_id != @region_ids[2]
    end
    return false if localities.length.zero?
    localities[0].id
  end

  def junk_cell(value)
    ['00', '', '0', nil].include?(value)
  end

  def get_region_ids(codes)
    ids = []
    4.times do |i|
      code = codes[i]
      if code.nil?
        ids.push(nil)
      else
        begin
          parent_id = Geobase::Region.where(code: code, level: i + 1, country_id: @country_id).first.id
        rescue NoMethodError
          parent_id = nil
        end
        ids.push(parent_id)
      end
    end
    return ids
  end

  def print_memory_usage
    memory_before = `ps -o rss= -p #{Process.pid}`.to_i
    yield
    memory_after = `ps -o rss= -p #{Process.pid}`.to_i

    puts "Memory: #{((memory_after - memory_before) / 1024.0).round(2)} MB"
  end

  def print_time_spent
    time = Benchmark.realtime do
      yield
    end

    puts "\nTime: #{time.round(2)}"
  end

  def csv_file_parse(filename, code)
    print_memory_usage do
      print_time_spent do
        File.open(filename, 'r') do |file|
          csv = CSV.new(file, col_sep: "\t", headers: false)
          not_eof = true
          row_number = 0
          while not_eof
            begin
              if (@row = csv.shift)
                yield
              else not_eof = false
              end
              row_number += 1
              printf("\e[34m#Country:\e[0m %s \e[34m#Row:\e[0m %s\r",
                     code, row_number)
            rescue CSV::MalformedCSVError => e
              @error_log.info(e.message)
              next
            end
          end
        end
      end
    end
  end
end