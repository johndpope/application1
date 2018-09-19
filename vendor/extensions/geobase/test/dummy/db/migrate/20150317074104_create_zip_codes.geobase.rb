# This migration comes from geobase (originally 20131025072232)
class CreateZipCodes < ActiveRecord::Migration
  def change
    create_table :geobase_zip_codes do |t|
      t.string :code
      t.float :latitude
      t.float :longitude
      t.integer :primary_region_id, limit: 8
      t.integer :secondary_region_id, limit: 8

      t.timestamps
    end
    add_index :geobase_zip_codes, :code
    add_index :geobase_zip_codes, :primary_region_id
    add_index :geobase_zip_codes, :secondary_region_id

    create_table :geobase_localities_zip_codes do |t|
      t.integer :locality_id, limit: 8
      t.integer :zip_code_id, limit: 8
    end
    add_index :geobase_localities_zip_codes, :locality_id
    add_index :geobase_localities_zip_codes, :zip_code_id
  end
end
