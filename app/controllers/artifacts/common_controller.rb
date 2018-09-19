module Artifacts
    class CommonController < BaseController
        def home
            @total_images = Image.count
            @states_covered = Image.where.not(region1: nil).select('DISTINCT region1').count
            @counties_covered = Image.where.not(region2: nil).select('DISTINCT region2').count
            @cities_covered = Image.where.not(city: nil).select('DISTINCT city').count
            download_grouping = Hash[
                Image.group('1').order('2 desc').pluck('file_file_name IS NOT NULL, count(*)')
            ]
            total = download_grouping.values.inject(:+)
            @saved_images = download_grouping[true].to_f / total * 100
            @pending_images = download_grouping[false].to_f / total * 100
        end
    end
end
