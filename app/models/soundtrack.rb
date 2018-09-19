class Soundtrack < ActiveRecord::Base
  belongs_to :soundtrack_item, :polymorphic=>true
  belongs_to :author

  has_many :soundtrack_tags, dependent: :destroy
  has_many :media_tags, through: :soundtrack_tags
  has_many :soundtrack_genres, dependent: :destroy
  has_many :genres, through: :soundtrack_genres

  has_one :media_item

  attr_accessor :attachment

  has_attached_file :attachment,
      path: ":rails_root/public/system/imported_soundtracks/:id/:style/:basename.:extension",
      url:  "/system/imported_soundtracks/:id/:style/:basename.:extension"

  do_not_validate_attachment_file_type :attachment

  def self.by_tags(tags)
    return all unless tags.present?
    Soundtrack.joins('INNER JOIN soundtrack_tags ON (soundtracks.id = soundtrack_tags.soundtrack_id)')
        .joins('INNER JOIN media_tags ON (soundtrack_tags.tag_id = media_tags.id)')
        .where('LOWER(media_tags.name) IN (?)', tags.downcase.split(',').map{|e| e.strip})
  end

  def self.by_genre(genre)
    return all unless genre.present?
    unless genre == "-"
      Soundtrack.joins('INNER JOIN soundtrack_genres ON (soundtracks.id = soundtrack_genres.soundtrack_id)')
        .joins('INNER JOIN genres ON (soundtrack_genres.genre_id = genres.id)')
        .where('LOWER(genres.name) IN (?)', genre.downcase)
    else
      where("id not in (?)", SoundtrackGenre.pluck(:soundtrack_id))
    end
  end

  def self.by_duration(from, to)
    return all unless from.present? && to.present?
    where("duration BETWEEN ? AND ?", from, to)
  end

  def self.by_title_or_author(search_str)
    return all unless search_str.present? && !search_str.blank?
    where("LOWER(title) LIKE ? OR LOWER(authors.initials) LIKE ?", "%#{search_str.downcase}%", "%#{search_str.downcase}%")
  end

  after_create do
    MediaItem.create(media_id: self.id, media_type: self.class.name)
  end
end
