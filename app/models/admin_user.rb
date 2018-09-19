class AdminUser < ActiveRecord::Base
	include CSVAccessor
	include Referable
	extend Enumerize
	ROLES = {admin: 1, crew_member: 2, content_manager: 3, client: 4}

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :rememberable, :trackable
  enumerize :roles, in: ROLES
	validates_presence_of :roles, message: "Role cannot be blank"
	#validates_length_of :password, minimum: 8, message: "Password should have at least 8 characters"
  belongs_to :client
  belongs_to :admin_user_company
	belongs_to :country, class_name: 'Geobase::Country'


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

  def username
    email
  end

  def full_name
    name_array = [first_name, last_name].compact.reject(&:empty?)
    name_array.present? ? name_array.join(" ") : email
  end
end
