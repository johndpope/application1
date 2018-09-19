Yt::Resource.class_eval do
  attr_reader :proxy_address
  attr_reader :proxy_port
  attr_reader :api_key

  def proxy_address
    proxy_address = @proxy_address
  end

  def proxy_port
    proxy_port = @proxy_port
  end

  def api_key
    api_key = @api_key
  end

  # @private
  def initialize(options = {})
    @url = URL.new(options[:url]) if options[:url]
    @id = options[:id] || (@url.id if @url)
    @auth = options[:auth]
    @snippet = Yt::Snippet.new(data: options[:snippet]) if options[:snippet]
    @status = Yt::Status.new(data: options[:status]) if options[:status]
    @proxy_address = options[:proxy_address] if options[:proxy_address]
    @proxy_port = options[:proxy_port] if options[:proxy_port]
    @api_key = options[:api_key] if options[:api_key]
  end
end

Yt::Actions::List.class_eval do
  def list_params
    path = "/youtube/v3/#{list_resources.camelize :lower}"
    {}.tap do |params|
      params[:method] = :get
      params[:host] = 'www.googleapis.com'
      params[:auth] = @auth
      params[:path] = path
      params[:exptected_response] = Net::HTTPOK
      #params[:api_key] = Yt.configuration.api_key if Yt.configuration.api_key
      params[:api_key] = @parent.api_key
      params[:proxy_address] = @parent.proxy_address
      params[:proxy_port] = @parent.proxy_port
    end
  end
end

Yt::Request.class_eval do
  def initialize(options = {})
    @method = options.fetch :method, :get
    @expected_response = options.fetch :expected_response, Net::HTTPSuccess
    @response_format = options.fetch :response_format, :json
    @host = options[:host]
    @path = options[:path]
    @params = options.fetch :params, {}
    # Note: This is to be invoked by auth-only YouTube APIs.
    @params[:key] = options[:api_key] if options[:api_key]
    # Note: This is to be invoked by all YouTube API except Annotations,
    # Analyitics and Uploads
    camelize_keys! @params if options.fetch(:camelize_params, true)
    @request_format = options.fetch :request_format, :json
    @body = options[:body]
    @headers = options.fetch :headers, {}
    @auth = options[:auth]
    @proxy_address = options[:proxy_address]
    @proxy_port = options[:proxy_port]
    @api_key = options[:api_key]
  end

  # Send the request to the server, allowing ActiveSupport::Notifications
  # client to subscribe to the request.
  def send_http_request
    net_http_options = [uri.host, uri.port, @proxy_address, @proxy_port, use_ssl: true]
    ActiveSupport::Notifications.instrument 'request.yt' do |payload|
      payload[:method] = @method
      payload[:request_uri] = uri
      payload[:response] = Net::HTTP.start(*net_http_options) do |http|
        http.request http_request
      end
    end
  end
end
