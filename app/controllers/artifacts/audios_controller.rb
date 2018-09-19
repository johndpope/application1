module Artifacts
  require 'open-uri'
  
  class AudiosController < BaseController
    AUDIOS_COUNT_DEFAULT_LIMIT = 25
    skip_before_filter :verify_authenticity_token, only: [:reject]
    def index
      @api = params[:api]
      search = { total: 0, items: [], next_href: '' }
      params[:limit] = AUDIOS_COUNT_DEFAULT_LIMIT unless params[:limit].present?
      options = params

      if params[:q].present? || @api.blank?
        options = params.merge(q: params[:q],
                               page: params[:page],
                               limit: params[:limit])
      end

      api_prefix = @api.blank? ? '' : @api.titleize
      search = "Artifacts::#{api_prefix}Audio".constantize.list(options)
      @total_count = search.count
      # @next_href = search[:next_href] unless search[:next_href].empty?
      return false if @total_count.zero?
      @audios = Kaminari.paginate_array(
        search[:items],
        total_count: search[:total]
      ).page(params[:page]).per(params[:limit])
      @audio_artists = Artifacts::Audio.joins("LEFT OUTER JOIN artifacts_artists ON artifacts_artists.id = artifacts_audios.artifacts_artist_id").
        select("artifacts_audios.id,artifacts_artists.name as artist_name").
        where("artifacts_audios.id" => search[:items].map{|item| item.id}).
        map{|a| {a.id => a.artist_name}}.inject(:merge)
    end

    def new
    end

    def create
      type = params[:audios][:type].to_s.capitalize
      audio_class = "Artifacts::#{type}Audio".constantize
      @audio = audio_class.new

      if !params[:audios][:file].blank?
        file = params[:audios][:file]
        file_name = params[:audios][:file].original_filename.to_s
        @audio.title = File.basename(file_name).gsub(File.extname(file_name),'').to_s.humanize
      end

      @audio.client_id = params[:audios][:client_id] unless params[:audios][:client_id].blank?
      @audio.sound_type = params[:audios][:sound_type] unless params[:audios][:sound_type].blank?
      @audio.attribution_required = params[:audios][:attribution_required] unless params[:audios][:attribution_required].blank?
      @audio.mood = params[:audios][:mood] unless params[:audios][:mood].blank?
      @audio.instrument = params[:audios][:instrument] unless params[:audios][:instrument].blank?
      @audio.tag_list = params[:audios][:tags] unless params[:audios][:tags].blank?
      @audio.artifacts_artist_id = params[:audios][:artifacts_artist_id] unless params[:audios][:artifacts_artist_id].blank?
      @audio.source = params[:audios][:source] unless params[:audios][:source].blank?
      @audio.license_type = params[:audios][:license_type] unless params[:audios][:license_type].blank?
      @audio.is_approved = params[:audios][:is_approved] unless params[:audios][:is_approved].blank?
      @audio.description = params[:audios][:description] unless params[:audios][:description].blank?
      @audio.genres = Genre.where(id: params[:audios][:genre_id].split(',')) unless params[:audios][:genre].blank?
      @audio.file = params[:audios][:file] unless params[:audios][:file].blank?

      respond_to do |format|
        if @audio.save
          unless params[:audios][:screen].blank?
            begin
              screen_file = params[:audios][:screen]
              screen = Screenshot.new
              screen.image = screen_file
              extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
              screen.image_file_name = File.basename(@audio.id.to_s)[0..-1] + extension
              @audio.screenshots << screen
            rescue
            end
          end
          format.js{render status: :ok}
        else
          format.js{render status: :fail}
        end
      end

     end

    def import
      import_soundcloud if params[:api] == 'Soundcloud'
      respond_to do |format|
        format.js
      end
    end

    def import_soundcloud
      @log ||= Logger.new("#{Rails.root}/log/soundcloud.log")
      client = SoundCloud.new(client_id: CONFIG['soundcloud']['client_id'])
      @audio = client.get("/tracks/#{params[:audio_id]}")
      @author = client.get("/users/#{@audio[:user_id]}")
      @track_author = Artifacts::Author.new
      @track_author.type = 'soundcloud'
      @track_author.username = @author[:username]
      @track_author.name = @author[:full_name]
      @track_author.url = @author[:permalink_url]
      @track_author.source_id = @author[:id]
      @track_author.avatar = URI.parse(@author[:avatar_url].gsub("https", "http"))
      @track_author.save
      @track = Artifacts::Audio.new
      @track.author_id = @track_author.id
      track_url = @audio[:download_url].to_s +
                  "?client_id=#{CONFIG['soundcloud']['client_id']}"
      begin
        @track.file = URI.parse(track_url)
      rescue RuntimeError => e
        @log.info(e.message)
        urls = e.message.split(' -> ')
        @track.file = URI.parse(urls[1])
        @log.info('URL:')
        @log.info(urls[1])
        @log.info('FILE:')
        @log.info(@track.file)
      end
      @track.url = @audio[:permalink_url]
      @track.description = @audio[:description]
      @track.type	= 'Artifacts::SoundcloudAudio'
      @track.title = @audio[:title]
      @track.duration = @audio[:duration]
      @track.license_url = @audio[:purchase_url]
      # @track.popularity
      # @track.monetization
      # @track.audio_category
      # @track.has_voice
      # @track.sound_type
      # @track.mood
      # @track.instrument
      # @track.source
      # @track.license_type
      # @track.is_approved
      @track.save
    end

    def edit
      @audio = Artifacts::Audio.find(params[:id])
      respond_to do |format|
        format.js
      end
    end

    def update
      @audio = Artifacts::Audio.find(params[:id])
      if !@audio.type.blank?
        type = 'artifacts_' + @audio.type.split('::').last.underscore.split('_').first + '_audio'
      else
        type = 'artifacts_audio'
      end

      genres = params["#{type}"]["genres"].reject(&:blank?)
      @audio.genres = Genre.where(:id => genres)
      @audio.update_attributes(audio_params)

      respond_to do |format|
        format.js
      end
    end

    def group_update
      items = params["items"]
      items.map{|k,v| Artifacts::Audio.find(k).update_attributes(:is_approved => v)}
    end

    def destroy
      @audio = Artifacts::Audio.find(params[:id])
      @audio.destroy!
    end

    def youtube_audio_library
      response = if params[:finished] == "true"
        if params["music_type"] == "audio"
          Utils.pushbullet_broadcast("Youtube audio bot has finished at #{Time.now}", "Youtube audio bot has finished, please check data.")
          {status: 200}
        end
      else
        {status: 500}
      end
      render json: response, status: response[:status]
    end

    private
  		def before_index
  			@search = Artifacts::Audio.search(params[:q])
  		end

      def audio_params
        type = '_' + @audio.type.split('::').last.underscore.split('_').first.to_s unless @audio.type.blank?
        params.require("artifacts#{type}_audio".to_sym).permit(:client_id, :title, :sound_type, :attribution_required, :mood, :instrument, :tag_list, :artifacts_artist_id, :source, :license_type, :is_approved, :description, :has_voice)
      end

  end
end
