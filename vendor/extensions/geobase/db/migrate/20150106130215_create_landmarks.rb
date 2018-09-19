class CreateLandmarks < ActiveRecord::Migration
  def change
    create_table :geobase_landmarks do |t|
      t.integer :locality_id
      t.integer :region_id
      t.integer :country_id
      t.string  :name
      t.integer :woeid
      t.float :latitude
      t.float :longitude
      t.timestamps
    end

    add_index :geobase_landmarks, :locality_id
    add_index :geobase_landmarks, :region_id
    add_index :geobase_landmarks, :country_id
    add_index :geobase_landmarks, :name
    add_index :geobase_landmarks, [:latitude, :longitude]
    add_index :geobase_landmarks, :latitude
    add_index :geobase_landmarks, :longitude
    add_index :geobase_landmarks, :woeid

    execute <<-SQL
      CREATE INDEX index_geobase_landmarks_on_lower_name
      ON geobase_landmarks
      USING btree
      (lower(name::text) COLLATE pg_catalog."default");

      CREATE INDEX index_geobase_landmarks_on_lower_name_and_locality_id
      ON geobase_landmarks
      USING btree
      (lower(name::text) COLLATE pg_catalog."default", locality_id);

      CREATE INDEX index_geobase_landmarks_on_lower_name_and_region_id
      ON geobase_landmarks
      USING btree
      (lower(name::text) COLLATE pg_catalog."default", region_id);

      CREATE INDEX index_geobase_landmarks_on_lower_name_and_country_id
      ON geobase_landmarks
      USING btree
      (lower(name::text) COLLATE pg_catalog."default", country_id)
    SQL
  end
end
