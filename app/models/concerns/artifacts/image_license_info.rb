module Artifacts::ImageLicenseInfo
	def license_info
		license_info = {}
		license_info[:license_name] = if is_local?
																		"EchoVideoBlender Content License"
																	elsif !license_name.blank?
																		license_name
																	elsif !license_url.blank?
																		license_url
																	end
		license_info[:license_url] = license_url
		license_info[:author_name] = is_local? ? "EchoVideoBlender" : author.try(:formatted_name)
		license_info[:author_url] = is_local? ? '' : author.try(:url)
		license_info[:image_url] = is_local? ? file.try(:url) : url
		license_info[:image_title] = title
		license_info[:license_acronym] = license_acronym
		license_info
	end

	def license_acronym
		return if license_url.blank?
		acronyms_by_license_names = {"Public Domain Dedication (CC0)" => "CC0",
			"Attribution-NonCommercial License" => "BY-NC",
			"Attribution-ShareAlike LicenseAttribution-ShareAlike License" => "BY-SA",
			"Attribution-NoDerivs License" => "BY-ND",
			"Attribution-NonCommercial-ShareAlike LicenseAttribution-NonCommercial-ShareAlike License" => "BY-NC-SA",
			"Attribution LicenseAttribution License" => "BY",
			"Public Domain Mark" => "CC0",
			"Attribution-NonCommercial-NoDerivs License" => "BY-NC-ND",
			"Free for commercial use (Include link to authors website)" => "cc0",
			"Creative Commons Deed CC0" => "CC0"}

		acronyms_by_license_urls = {"https://creativecommons.org/licenses/by/2.0/" => "BY",
			"https://creativecommons.org/licenses/by-nc-nd/2.0/" => "BY-NC-ND",
			"https://creativecommons.org/licenses/by-nc/2.0/" => "BY-NC",
			"https://creativecommons.org/licenses/by-nc-sa/2.0/" => "BY-NC-SA",
			"https://creativecommons.org/publicdomain/mark/1.0/" => "CC0",
			"http://creativecommons.org/publicdomain/zero/1.0/deed.en" => "CC0",
			"https://creativecommons.org/publicdomain/zero/1.0/" => "CC0",
			"https://creativecommons.org/licenses/by-sa/2.0/" => "BY-SA",
			"https://creativecommons.org/licenses/by-nd/2.0/" => "BY-ND"}

			acronym = if acronyms_by_license_urls.keys.include? license_url.downcase
									acronyms_by_license_urls[license_url.downcase]
								elsif acronyms_by_license_names.keys.include? license_url
									acronyms_by_license_names[license_url]
								end
	end
end
