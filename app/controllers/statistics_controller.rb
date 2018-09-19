require 'nokogiri'

class StatisticsController < ApplicationController
	def polygons()
		file = File.read(File.join(Rails.root.join('public','polygons',"#{params[:country_code].downcase}.xml")))
		xml = Nokogiri::XML(file)
		render json: Hash.from_xml(xml.to_xml)
	end

	def youtube_monthly_statistics()
		@time_periods = YoutubeVideo::time_periods
		@columns = 5
	end
end
