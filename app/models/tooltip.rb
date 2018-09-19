class Tooltip < ActiveRecord::Base
  include Reversible
  BLACK_LIST = %w(versions taggable_taggings taggable_tags invoices source_videos wordings client_donors client_recipients client_donor_source_videos dealer_certifications references)
  EXCLUDED_FIELDS = {
    clients: %w(logo_file_name logo_content_type logo_file_size logo_updated_at badge_logo_file_name badge_logo_file_size badge_logo_content_type badge_logo_updated_at),
    products: %w(logo_file_name logo_content_type logo_file_size logo_updated_at),
    templates_aae_projects: %w(id thumbnail_content_type thumbnail_file_size thumbnail_updated_at video_content_type video_file_size video_updated_at xml_content_type xml_file_size xml_updated_at),
    templates_aae_project_texts: %w(id guid aae_project_id encoded_value text_limit presents_in_project name_presents value_presents corrected_value),
    templates_aae_project_images: %w(id guid media_type aae_project_id presents_in_project name_presents)
  }

  validates_presence_of :table_name, :table_column, :value
end
