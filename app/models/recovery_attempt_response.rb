class RecoveryAttemptResponse < ActiveRecord::Base
  include Reversible
  has_and_belongs_to_many :google_account_activities
  validates :response, presence: true, length: { in: 3..1000 }
  validates :response_type, presence: true
  RESPONSE_TYPES =  {"1st attempt"=>1, "2nd attempt - No respond"=>2, "2nd attempt - Got respond"=>3, "3rd attempt"=>4, "4th attempt"=>5, "Still disabled, but got positive response"=>6}
  extend Enumerize
  enumerize :response_type, :in=> RESPONSE_TYPES

  def self.by_id(id)
    return all unless id.present?
    where("id = ?", id.strip)
  end

  def self.by_response(response)
    return all unless response.present?
    where("lower(response) like ?", "%#{response.downcase}%")
  end

  def self.by_response_type(response_type)
    return all unless response_type.present?
    where("response_type = ?", response_type)
  end
end
