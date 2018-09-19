class AddFieldsToGeobaseLandmark < ActiveRecord::Migration
  def change
    add_column :geobase_landmarks, :category, :string
    add_index :geobase_landmarks, :category
    add_column :geobase_landmarks, :address, :string
    add_index :geobase_landmarks, :address
    add_column :geobase_landmarks, :phone_number, :string
    add_index :geobase_landmarks, :phone_number
    add_column :geobase_landmarks, :website, :string
    add_index :geobase_landmarks, :website
    add_column :geobase_landmarks, :source_url, :string
    add_index :geobase_landmarks, :source_url
  end
end
