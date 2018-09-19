class CreateLocalities < ActiveRecord::Migration
  def change
    create_table :geobase_localities do |t|
      t.string :code
      t.string :name
      t.integer :woeid
      t.integer :population
      t.integer :locality_type
      t.text :nicknames
      t.integer :primary_region_id, limit: 8

      t.timestamps
    end
    add_index :geobase_localities, :primary_region_id
    add_index :geobase_localities, :population
    add_index :geobase_localities, :name
    add_index :geobase_localities, :woeid
  end
end
