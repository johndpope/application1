class Social::Image < ActiveRecord::Base
  belongs_to :user
  belongs_to :license_proof

  include Reversible
  extend Enumerize

  LIMITS = %w(2 4 10 20 30 40 50 100)
  IMAGE_TYPES = {locality: 1, event: 2, sick_children: 3, diabetes: 4}
  enumerize :media_type, in: IMAGE_TYPES, scope: true

  has_attached_file :file,
    styles: {thumb: '320x240^'}, preserve_files: true
  validates_attachment_content_type :file,
    content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif"],
    size: {greater_than: 0.bytes, less_than: 25.megabytes}

  before_save :set_width_and_height

  acts_as_taggable
  acts_as_taggable_on :source_tags
	acts_as_taggable_on :special_tags

  DEFAULTS = {
    limit: 50
  }

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
      "url" => file.url(:thumb),
      "title" => read_attribute(:file_file_name).split('.')[0],
      "delete_url" => "/shared_media/images/#{self.id}",
      "delete_type" => "DELETE",
      "tag_list" => self.tag_list,
      "notes" => read_attribute(:notes)
    }
  end

  def to_json_format
    {
      "id" => read_attribute(:id),
      "url" => file.url(:thumb),
      "name" => read_attribute(:file_file_name),
      "size" => read_attribute(:file_file_size),
      "width" => read_attribute(:width),
      "height" => read_attribute(:height),
      "deleteUrl" => "/sandbox/video_marketing_campaign_forms/#{self.id}/client_images_destroy",
      "delete_type" => "DELETE"
    }
  end

  class << self
    def list(options = {})
      limit = options[:limit] || DEFAULTS[:limit]
      criteria = options[:ransack] || {}
      criteria[:title_or_notes_or_tags_name_or_special_tags_name] = options[:q]
      scope = order(created_at: :desc).ransack(criteria).result(distinct: true)
      scope = scope.where(user_id: options[:user_id])
      result = {
        total: scope.count,
        items: scope.page(options[:page]).per(limit).to_a,
        scope: scope
      }
      result
    end

    def distribution_by_tag
      grouping = Social::Image.joins(
        <<-SQL
          LEFT OUTER JOIN taggable_taggings tti
            ON social_images.id = tti.taggable_id
              AND tti.taggable_type = 'Social::Image'
              AND tti.context = 'tags'
        SQL
      ).joins("LEFT OUTER JOIN taggable_tags tt ON tti.tag_id = tt.id AND tt.name IS NOT NULL").
      group('1').order('2 DESC').pluck('tt.name, count(*)')
      Hash[grouping]
    end

    def distribution_by_region1
      Hash[
        where.not(region1: ['', nil]).group('1,2').order('3 DESC').pluck('country,region1,count(*)').map { |e|
          state = Geobase::Region.find(e[1]).name
          country = Geobase::Country.find(e[0]).name
          [[[e[1],state],[e[0],country]],e[2]]
        }
      ]
    end

    def distribution_by_region2
      Hash[
        where.not(region2: ['', nil]).group('1,2,3').order('4 DESC, 3')
        .pluck('country,region1,region2,count(*)').map do |e|
          county = Geobase::Region.find(e[2]).name
          state = Geobase::Region.find(e[1]).name
          [[[e[2],county],[e[1],state]], e[3]]
        end
      ]
    end

    def distribution_by_city
      Hash[
        where.not(city: ['', nil]).group('1,2').order('3 DESC').pluck('region1,city,count(*)').map { |e|
          city = Geobase::Locality.find(e[1]).name
          state = Geobase::Region.find(e[0]).name
          [[[e[1],city],[e[0],state]], e[2]]
        }
      ]
    end

  end

  protected

    def set_width_and_height
      if (path = file.staged_path)
        geometry = Paperclip::Geometry.from_file(path)
        self.width = geometry.width.to_i
        self.height = geometry.height.to_i
      else
        unless file.path
          self.width = nil
          self.height = nil
        end
      end
      true
    end

end
