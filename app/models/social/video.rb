class Social::Video < ActiveRecord::Base
  belongs_to :user
  belongs_to :clients, class_name: "Client", foreign_key: "client_id"

  include Reversible
  extend Enumerize
  LIMITS = %w(2 4 10 20 30 40 50 100)
  DEFAULTS = {
    limit: 15
  }

  has_attached_file :file
  validates_attachment :file, allow_blank: true,
    content_type: {content_type: ['video/mp4'], message: 'Invalid content type'},
    size: {greater_than: 0.bytes, less_than: 250.megabytes, message: 'File size exceed the limit allowed'}

  acts_as_taggable
  acts_as_taggable_on :source_tags
	acts_as_taggable_on :special_tags

  attr_accessor :special_tags

  VIDEO_TYPES = {event: 1, testimonial: 2, informative: 3}
  enumerize :media_type, in: VIDEO_TYPES, scope: true

   def to_jq_upload
      {
      "country" => read_attribute(:country).blank? ? "" : Geobase::Country.find(read_attribute(:country)),
      "region1" => read_attribute(:region1).blank? ? "" : Geobase::Region.find(read_attribute(:region1)),
      "region2" => read_attribute(:region2).blank? ? "" : Geobase::Region.find(read_attribute(:region2)),
      "city" => read_attribute(:city).blank? ? "" : Geobase::Locality.find(read_attribute(:city)),
      "id" => read_attribute(:id),
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "file_content_type" => read_attribute(:file_content_type),
      "url" => file.url(:original),
      "title" => read_attribute(:title),
      "tag_list" => self.tag_list,
      "notes" => read_attribute(:notes)
    }
  end

  class << self
    def list(options = {})
      limit = options[:limit] || DEFAULTS[:limit]
      criteria = options[:ransack] || {}
      criteria[:title_or_file_file_name_or_notes_cont] = options[:q]
      scope = Social::Video.ransack(criteria).result(distinct: true)
      scope = scope.where(user_id: options[:user_id])
      result = {
        total: scope.count,
        items: scope.page(options[:page]).per(limit).to_a
      }
      result
    end
  end

end
