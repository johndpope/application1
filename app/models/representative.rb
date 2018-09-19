class Representative < ActiveRecord::Base
  include Reversible
  belongs_to :client
  has_and_belongs_to_many :products
  validates :first_name, presence: true
  validates :last_name, presence: true

  PHONE_TYPES = {mobile: "m:", work: "w:", office: "f:", home: "h:", other: "o:"}

  def phones
    (read_attribute(:phones) || []).map do |p|
      #p.gsub(/[^\d]/, '')
      p =~ /^\d{12}$/ ? "#{p[0..1]}(#{p[2..4]}) #{p[5..7]}-#{p[8..12]}" : p
    end
  end

  def phones_csv
    phones.try(:join, ', ')
  end

  def phones_csv=(values)
    self.phones = values.strip.split(/\s*,\s*/)
  end

  def full_name
    [ first_name, mid_name, last_name ].compact.join( ' ')
  end
end
