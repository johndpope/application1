module Artifacts
  require 'net/https'
  class JamendoAudio < Audio
    JAMENDO_DEFAULTS = { type: 1,
                         audioformat: 'mp31',
                         limit: 10 }.freeze
    JAMENDO_AUDIOFORMAT = %w[mp31 mp32 ogg flac].freeze
    TRACK_TYPE = %w[albumtrack\ single albumtrack single].freeze
    SORT_ORDER = %w[relevance buzzrate downloads_week downloads_month
                    downloads_total listens_week listens_month listens_total
                    popularity_week popularity_month popularity_total name
                    album_name artist_name releasedate duration id].freeze
    BOOST = %w[buzzrate downloads_week downloads_month downloads_total
               listens_week listens_month listens_total popularity_week
               popularity_month popularity_total].freeze

    attr_accessor :audioformat, :type, :tags, :boost, :order, :image, :duration,
                  :musicinfo, :shareurl

    class << self

      def api_call(query, entity = 'tracks')
        uri = URI.parse("https://api.jamendo.com/v3.0/#{entity}/")
        query = { client_id: CONFIG['jamendo']['client_id'] }.merge(query)
        uri.query = URI.encode_www_form(query)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Get.new(uri.request_uri)
        response = http.request(request)
        response.body
      end

      def list(options = {})

        params = Audio::DEFAULTS.merge(JAMENDO_DEFAULTS).merge(options)
        params.symbolize_keys!
        query = { format: 'json',
                  include: 'licenses+musicinfo',
                  limit: params[:limit],
                  artist_name: params[:artist_name],
                  name: params[:name],
                  tags: params[:search_tags],
                  album_name: params[:album_name],
                  audioformat: params[:audioformat],
                  order: params[:order],
                  boost: params[:boost],
                  type: TRACK_TYPE[params[:type].to_i],
                  search: params[:q] }
        response = api_call(query)

        items = []
        JSON.parse(response)['results'].each do |audio|
          item = Artifacts::JamendoAudio.new
          item.file_file_name = audio['audio']
          item.title = audio['name']
          item.source = audio['artist_name']
          item.client_id = audio['id']
          item.duration = audio['duration']
          item.shareurl = audio['shareurl']
          item.image = audio['image']
          item.musicinfo = audio['musicinfo']
          items.push(item)
        end

        result = { total: items.count,
                   items: items }
      end
    end

    def import; end
  end
end
