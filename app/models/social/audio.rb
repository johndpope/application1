class Social::Audio < ActiveRecord::Base
  belongs_to :user
  belongs_to :clients, class_name: "Client", foreign_key: "client_id"

  include Reversible
  extend Enumerize

  AUDIO_TYPES = {classic: 1, modern: 2, jazz: 3, holiday: 4, cinematic: 5}
  enumerize :media_type, in: AUDIO_TYPES, scope: true
  LIMITS = %w(2 4 10 20 30 40 50 100)
  DEFAULTS = {
    limit: 15
  }

  has_attached_file :file
  validates_attachment :file, allow_blank: true,
    content_type: {content_type: ['audio/mpeg','audio/mp3','audio/wav'], message: 'Invalid content type'},
    size: {greater_than: 0.bytes, less_than: 15.megabytes, message: 'File size exceed the limit allowed'}

  acts_as_taggable
  acts_as_taggable_on :source_tags
	acts_as_taggable_on :special_tags

  attr_accessor :special_tags
  def to_jq_upload
    {
      "id" => read_attribute(:id),
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "file_content_type" => read_attribute(:file_content_type),
      "url" => file.url(:original),
      "title" => read_attribute(:title),
      "delete_type" => "DELETE",
      "tag_list" => self.tag_list,
      "notes" => read_attribute(:notes)
    }
  end

  class << self
    def list(options = {})
      limit = options[:limit] || DEFAULTS[:limit]
      criteria = options[:ransack] || {}
      criteria[:title_or_file_file_name_or_notes_cont] = options[:q]
      scope = Social::Audio.ransack(criteria).result(distinct: true)
      scope = scope.where(user_id: options[:user_id])
      result = {
        total: scope.count,
        items: scope.page(options[:page]).per(limit).to_a
      }
      result
    end
  end


end
