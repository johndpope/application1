module WordAI
  REGULAR_DEFAULTS = {
    email: CONFIG['wordai']['email'],
    hash: CONFIG['wordai']['hash'],
    quality: 50,
    sentence: 'on',
    paragraph: 'on'
  }
  TURING_DEFAULTS  = {
    email: CONFIG['wordai']['email'],
    hash: CONFIG['wordai']['hash'],
    quality: 'Regular',
    sentence: 'on',
    paragraph: 'on'
  }

	READ_TIMEOUT = 180

	def self.post_form(url, params, read_timeout = 60)
		req = Net::HTTP::Post.new(url.request_uri)
		req.form_data = params
		req.basic_auth url.user, url.password if url.user
		Net::HTTP.new(url.hostname, url.port).start {|http|
			http.read_timeout = read_timeout
			http.request(req)
		}
	end

  def self.regular(options = {})
    uri = URI.parse('http://wordai.com/users/regular-api.php')
    response = post_form(uri, REGULAR_DEFAULTS.merge(options), READ_TIMEOUT)
    spintax = response.body
    spintax.extend SpintaxParser
    spintax
  end

  def self.turing(options = {})
    uri = URI.parse('http://wordai.com/users/turing-api.php')
    response = Net::HTTP.post_form(uri, TURING_DEFAULTS.merge(options), READ_TIMEOUT)
    spintax = response.body
    spintax.extend SpintaxParser
    spintax
  end
end
