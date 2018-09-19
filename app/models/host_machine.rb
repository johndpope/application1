class HostMachine < ActiveRecord::Base
  include Reversible
  has_many :api_applications

	def display_name
		name_chunks = []
		name_chunks << url unless url.blank?
		name_chunks << "ID: #{id}"
		name_chunks.join(' ')
	end

  def normalized_url
    @url = self.url
    if @url.blank?
      ''
    else
      @url = "http://#{@url}" unless @url[/\Ahttp:\/\//] || @url[/\Ahttps:\/\//]
      URI.parse(@url).to_s
    end
  end
end
