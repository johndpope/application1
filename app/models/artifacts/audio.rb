class Artifacts::Audio < ActiveRecord::Base
  include Reversible
  extend Enumerize

  API_SOURCES_LIST = %w[Jamendo Soundcloud youtube].freeze
  LIMITS = %w[2 4 10 20 30 40 50 100].freeze
  DEFAULTS = { limit: 10 }.freeze
  LIMITS = %i[10 25 50 100].freeze
  SOUND_TYPE = {sound_music: 0, sound_effect: 1}
  ATTRIBUTION = {attribution_not_required: 0, attribution_required: 1, all_licenses: 2}
  MOOD = {angry: 0, bright: 1, calm: 2, dark: 3, dramatic: 4, funky: 5, happy: 6, inspirational: 7, romantic: 8, sad: 9}
  INSTRUMENT = {acoustic_guitar: 0, bass: 1, drums: 2, electric_guitar: 3, organ: 4, piano: 5}
  LICENSES = {
		'Standard Youtube License' => 1,
		'Creative Commons - Attribution' => 2
	}
  AUDIO_CATEGORIES = {"Alarms" => 1, "Ambiences" => 2, "Animals" => 3, "Cartoon" => 4, "Crowds" => 5, "Doors" => 6, "Emergency" => 7, "Foley" => 8, "Horror" => 9, "Household" => 10, "Human Sounds" => 11, "Human Voices" => 12, "Impacts" => 13, "Office" => 14, "Science Fiction" => 15, "Sports" => 16, "Tools" => 17, "Transportation" => 18, "Water" => 19, "Weapons" => 20, "Weather" => 21}

  enumerize :license_type, in: LICENSES, scope: true
  enumerize :attribution_required, in: ATTRIBUTION, scope: true
  enumerize :mood, in: MOOD, scope: true
  enumerize :audio_category, in: AUDIO_CATEGORIES, scope: true
	enumerize :instrument, in: INSTRUMENT, scope: true

  belongs_to :clients, class_name: "Client", foreign_key: "client_id"
  belongs_to :author
  belongs_to :artist, class_name: "Artifacts::Artist", foreign_key: "artifacts_artist_id"
  has_and_belongs_to_many :genres

  has_attached_file :file,
                    :path=>':rails_root/public/system/:base_class/:id_partition/:style/:basename.mp3',
                    :url=>'/system/:base_class/:id_partition/:style/:basename.mp3'
  validates_attachment_content_type :file, :content_type => ['audio/mpeg','audio/mp3', 'audio/wav', 'audio/mp4','video/mp3']
  validates_attachment_presence :file

  has_many :screenshots, as: :screenshotable, dependent: :destroy

	scope :left_joins_genres, -> {
		joins("LEFT JOIN artifacts_audios_genres ON artifacts_audios.id = artifacts_audios_genres.audio_id").
		joins("LEFT JOIN genres ON artifacts_audios_genres.genre_id = genres.id")
	}

  acts_as_taggable
  acts_as_taggable_on :source_tags
	acts_as_taggable_on :special_tags

  attr_accessor :special_tags

  include Rails.application.routes.url_helpers

  def to_jq_upload
    {
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "url" => file.url(:original),
      "delete_url" => artifacts_image_path(self),
      "delete_type" => "DELETE"
    }
  end

  def full_title
    artist.try(:name).present? ? "#{artist.name} - #{title}" : title
  end

  class << self
    def list(options = {})
      limit = options[:limit] || DEFAULTS[:limit]
      criteria = options[:ransack] || {}
      criteria[:title_or_description_or_tags_name_cont] = options[:q]
      scope = Artifacts::Audio.left_joins_genres.by_genre_id(criteria[:genre_eq]).ransack(criteria).result(distinct: true).order('created_at desc')
      result = {
        total: scope.count,
        items: scope.page(options[:page]).per(limit).to_a,
        scope: scope
      }
      result
    end

    def by_genre_id(genre_id)
      return all unless genre_id.present?
      where('genres.id = ?', genre_id.strip)
    end
  end

end
