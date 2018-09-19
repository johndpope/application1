class EmailAccountsSetup < ActiveRecord::Base
  include Reversible
  belongs_to :contract
  validates :contract_id, presence: true
  validates_uniqueness_of :contract_id, :if => Proc.new{|eas| eas.contract_id.present? }
  belongs_to :client
  belongs_to :country, class_name: 'Geobase::Country'
  has_one :youtube_setup
  has_many :email_accounts

  PACKAGES = {top_cities: 1, population: 2, states: 3, national: 4, regional: 5}
  extend Enumerize
  enumerize :package, in: PACKAGES

  validates :accounts_number, presence: true
  validate :validate_by_package

  def display_name
    "Email Accounts Setup ##{self.id} | #{self.try(:contract).try(:display_name)}"
  end

  private
    def validate_by_package
      states_array = self.states
      cities_array = self.cities
      counties_array = self.counties
      case self.package.try(:value)
      when 1
        if !self.top_cities_filter.present? || self.top_cities_filter == 0
          errors.add(:top_cities_filter, "can't be blank with package 'By top cities'")
        end
      when 2
        if !self.population_filter.present? || self.population_filter == 0
          errors.add(:population_filter, "can't be blank with package 'By cities with population greater than ...'")
        end
      when 3
        states_array.delete("")
        if !states_array.present?
          errors.add(:states, "can't be blank with package 'By states'")
        end
      when 5
        states_array.delete("")
        cities_array.delete("")
        counties_array.delete("")
        if !states_array.present?
          errors.add(:states, "can't be blank with package 'Regional'")
        end
        if !cities_array.present? && !counties_array.present?
          errors.add(:cities, "or counties can't be blank with package 'Regional'")
        end
      end
    end
end
