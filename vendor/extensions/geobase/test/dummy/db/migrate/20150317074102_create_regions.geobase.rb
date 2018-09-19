# This migration comes from geobase (originally 20131025070520)
class CreateRegions < ActiveRecord::Migration
  def change
    create_table :geobase_regions do |t|
      t.string :code
      t.string :name
      t.integer :woeid
      t.integer :level
      t.string :motto
      t.string :flower
      t.string :bird
      t.text :nicknames
      t.text :nickname_explanation
      t.integer :country_id, limit: 8
      t.integer :parent_id, limit: 8

      t.timestamps
    end
    add_index :geobase_regions, :country_id
    add_index :geobase_regions, :parent_id
    add_index :geobase_regions, :code
    add_index :geobase_regions, :level
    add_index :geobase_regions, :motto
    add_index :geobase_regions, :flower
    add_index :geobase_regions, :bird
    add_index :geobase_regions, :woeid
  end
end
