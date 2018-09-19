class User < ActiveRecord::Base
  TEMP_EMAIL_PREFIX = 'change@me'
  devise :database_authenticatable, :omniauthable, omniauth_providers: [:facebook, :twitter, :google_oauth2]

  has_many :services, :dependent => :destroy
  validates :name, :email, :presence => true

  def self.find_for_oauth(auth, signed_in_resource = nil)
    service = Service.find_for_oauth(auth)
    user = signed_in_resource ? signed_in_resource : service.user
      if user.nil?
        email = auth.info.email
        user = User.where(:email => email).first if email
        if user.nil?
          user = User.new(
            name: auth.extra.raw_info.name ? auth.extra.raw_info.name : auth.info.name,
            email: email ? email : "#{TEMP_EMAIL_PREFIX}-#{auth.uid}-#{auth.provider}.com", #vk & twitter email:nil
          )
          user.save!
        end
      end
      if service.user != user
        service.user = user
        service.uname = user.name
        service.uemail = user.email
        service.save!
      end
    user
  end

  def self.new_with_session(params, session)
    if session["devise.user_attributes"]
      new(session["devise.user_attributes"], without_protection: true) do |user|
        user.attributes = params
        user.valid?
      end
    else
      super
    end
  end

  def self.destroy
    super
  end


end
