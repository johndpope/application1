# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150317074106) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "geobase_countries", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "woeid"
    t.string   "primary_region_name"
    t.string   "secondary_region_name"
    t.string   "ternary_region_name"
    t.string   "quaternary_region_name"
    t.integer  "region_levels"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "geobase_countries", ["code"], name: "index_geobase_countries_on_code", using: :btree
  add_index "geobase_countries", ["woeid"], name: "index_geobase_countries_on_woeid", using: :btree

  create_table "geobase_landmarks", force: true do |t|
    t.integer  "locality_id"
    t.integer  "region_id"
    t.integer  "country_id"
    t.string   "name"
    t.integer  "woeid"
    t.float    "latitude"
    t.float    "longitude"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "geobase_landmarks", ["country_id"], name: "index_geobase_landmarks_on_country_id", using: :btree
  add_index "geobase_landmarks", ["country_id"], name: "index_geobase_landmarks_on_lower_name_and_country_id", using: :btree
  add_index "geobase_landmarks", ["latitude", "longitude"], name: "index_geobase_landmarks_on_latitude_and_longitude", using: :btree
  add_index "geobase_landmarks", ["latitude"], name: "index_geobase_landmarks_on_latitude", using: :btree
  add_index "geobase_landmarks", ["locality_id"], name: "index_geobase_landmarks_on_locality_id", using: :btree
  add_index "geobase_landmarks", ["locality_id"], name: "index_geobase_landmarks_on_lower_name_and_locality_id", using: :btree
  add_index "geobase_landmarks", ["longitude"], name: "index_geobase_landmarks_on_longitude", using: :btree
  add_index "geobase_landmarks", ["name"], name: "index_geobase_landmarks_on_name", using: :btree
  add_index "geobase_landmarks", ["region_id"], name: "index_geobase_landmarks_on_lower_name_and_region_id", using: :btree
  add_index "geobase_landmarks", ["region_id"], name: "index_geobase_landmarks_on_region_id", using: :btree
  add_index "geobase_landmarks", ["woeid"], name: "index_geobase_landmarks_on_woeid", using: :btree

  create_table "geobase_localities", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "woeid"
    t.integer  "population"
    t.integer  "locality_type"
    t.text     "nicknames"
    t.integer  "primary_region_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "geobase_localities", ["name"], name: "index_geobase_localities_on_name", using: :btree
  add_index "geobase_localities", ["population"], name: "index_geobase_localities_on_population", using: :btree
  add_index "geobase_localities", ["primary_region_id"], name: "index_geobase_localities_on_primary_region_id", using: :btree
  add_index "geobase_localities", ["woeid"], name: "index_geobase_localities_on_woeid", using: :btree

  create_table "geobase_localities_zip_codes", force: true do |t|
    t.integer "locality_id", limit: 8
    t.integer "zip_code_id", limit: 8
  end

  add_index "geobase_localities_zip_codes", ["locality_id"], name: "index_geobase_localities_zip_codes_on_locality_id", using: :btree
  add_index "geobase_localities_zip_codes", ["zip_code_id"], name: "index_geobase_localities_zip_codes_on_zip_code_id", using: :btree

  create_table "geobase_regions", force: true do |t|
    t.string   "code"
    t.string   "name"
    t.integer  "woeid"
    t.integer  "level"
    t.string   "motto"
    t.string   "flower"
    t.string   "bird"
    t.text     "nicknames"
    t.text     "nickname_explanation"
    t.integer  "country_id",           limit: 8
    t.integer  "parent_id",            limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "geobase_regions", ["bird"], name: "index_geobase_regions_on_bird", using: :btree
  add_index "geobase_regions", ["code"], name: "index_geobase_regions_on_code", using: :btree
  add_index "geobase_regions", ["country_id"], name: "index_geobase_regions_on_country_id", using: :btree
  add_index "geobase_regions", ["flower"], name: "index_geobase_regions_on_flower", using: :btree
  add_index "geobase_regions", ["level"], name: "index_geobase_regions_on_level", using: :btree
  add_index "geobase_regions", ["motto"], name: "index_geobase_regions_on_motto", using: :btree
  add_index "geobase_regions", ["parent_id"], name: "index_geobase_regions_on_parent_id", using: :btree
  add_index "geobase_regions", ["woeid"], name: "index_geobase_regions_on_woeid", using: :btree

  create_table "geobase_zip_codes", force: true do |t|
    t.string   "code"
    t.float    "latitude"
    t.float    "longitude"
    t.integer  "primary_region_id",   limit: 8
    t.integer  "secondary_region_id", limit: 8
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "geobase_zip_codes", ["code"], name: "index_geobase_zip_codes_on_code", using: :btree
  add_index "geobase_zip_codes", ["primary_region_id"], name: "index_geobase_zip_codes_on_primary_region_id", using: :btree
  add_index "geobase_zip_codes", ["secondary_region_id"], name: "index_geobase_zip_codes_on_secondary_region_id", using: :btree

end
