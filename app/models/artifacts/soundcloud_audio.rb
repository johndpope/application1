module Artifacts
  class SoundcloudAudio < Audio
    SOUNDCLOUD_DEFAULTS = { bpm_from: 0,
                            bpm_to: 0,
                            duration_from: 0,
                            duration_to: 0,
                            offset: 0 }.freeze
    FILTER = %w[all public private].freeze
    LICENSE = %w[cc-by cc-by-nd cc-by-sa cc-by-nc-nd cc-by-nc-sa].freeze
    TYPES = %w[original remix live recording spoken podcast].freeze

    attr_accessor :sc_data, :embed_info

    class << self
      def list(options = {})
        @log ||= Logger.new("#{Rails.root}/log/soundcloud.log")
        params = Audio::DEFAULTS.merge(SOUNDCLOUD_DEFAULTS).merge(options)
        params.symbolize_keys!
        @log.info(params.to_yaml)
        client = SoundCloud.new(client_id: CONFIG['soundcloud']['client_id'])
        query = {}
        query[:q] = params[:q] unless params[:q].blank?
        query[:limit] = params[:limit] unless params[:limit].blank?
        query[:filter] = params[:filter].to_s unless params[:filter].blank?
        query[:license] = params[:license].to_s unless params[:license].blank?
        query[:tags] = params[:search_tags] unless params[:search_tags].blank?
        bpm = {}
        bpm[:from] = params[:bpm_from].to_i unless params[:bpm_from].to_i.zero?
        bpm[:to] = params[:bpm_to].to_i unless params[:bpm_to].to_i.zero?
        query[:bpm] = bpm unless bpm.blank?
        duration = {}
        duration[:from] = params[:duration_from].to_i unless params[:duration_from].to_i.zero?
        duration[:to] = params[:duration_to].to_i unless params[:duration_to].to_i.zero?
        query[:duration] = duration unless duration.blank?
        query[:types] = params[:type] unless params[:type].blank?
        query[:genres] = params[:genres] unless params[:genres].blank?
        query[:sharing] = 'public'
        query[:linked_partitioning] = 1
        query[:offset] = params[:offset]
        query['filter.license'] = 'to_use_commercially'
        @log.info(query.to_yaml)
        responce = client.get('/tracks', query)
        tracks = responce.collection
        items = []
        tracks.each do |track|
          item = Artifacts::SoundcloudAudio.new
          item.sc_data = track.to_h
          @log.info(responce.next_href)
          begin
            item.embed_info = client.get('/oembed', url: track.permalink_url)
          rescue SoundCloud::ResponseError
            @log.info("#{track.permalink_url} -- 404 Error")
          end
          items.push(item)
        end
        { total: items.count, items: items, next_href: responce.next_href }
      end

    end
    def import; end
  end
end