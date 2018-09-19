class Setting < ActiveRecord::Base
  include Reversible
  validates :name, presence: true, uniqueness: true
  validates :value, presence: true

  def self.get_value_by_name(name)
    setting = Setting.find_by_name(name)
    val = begin
      (eval name).to_s
    rescue
      nil
    end
    setting.nil? && val.present? ? Setting.create(name: name, value: val).try(:value) : setting.try(:value)
  end
end
