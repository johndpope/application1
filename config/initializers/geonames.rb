require 'geonames'
GeoNames.class_eval do
  def query(name, parameters, proxy=nil)
    default = {host: options[:host]}
    default[:username] = options[:username] if options[:username]

    uri = uris[name].expand(default.merge(parameters))
    proxy = URI.parse(proxy) unless proxy.nil?
    if block_given?
      open(uri.to_s, proxy: proxy){|io| yield(io.read) }
    else
      open(uri.to_s, proxy: proxy){|io| JSON.parse(io.read) }
    end
  end

  def get(parameters, proxy=nil)
    query(:get, parameters, proxy)
  end
end
