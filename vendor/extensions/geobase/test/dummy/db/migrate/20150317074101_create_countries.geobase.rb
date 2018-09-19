# This migration comes from geobase (originally 20131025070203)
class CreateCountries < ActiveRecord::Migration
  def change
    create_table :geobase_countries do |t|
      t.string :code
      t.string :name
      t.integer :woeid
      t.string :primary_region_name
      t.string :secondary_region_name
      t.string :ternary_region_name
      t.string :quaternary_region_name
      t.integer :region_levels

      t.timestamps
    end
    add_index :geobase_countries, :code
    add_index :geobase_countries, :woeid
  end
end
