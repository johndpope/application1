class AddPopulationsToGeobaseLocality < ActiveRecord::Migration
  def change
    add_column :geobase_localities, :population_2010, :integer
    add_index :geobase_localities, :population_2010
    add_column :geobase_localities, :population_2011, :integer
    add_index :geobase_localities, :population_2011
    add_column :geobase_localities, :population_2012, :integer
    add_index :geobase_localities, :population_2012
    add_column :geobase_localities, :population_2013, :integer
    add_index :geobase_localities, :population_2013
    add_column :geobase_localities, :population_2014, :integer
    add_index :geobase_localities, :population_2014
  end
end
