require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      def authenticate!
        if params[:admin_user]
          ldap = Net::LDAP.new
          ldap.host = CONFIG['ldap']['host']
          ldap.port = CONFIG['ldap']['port']
          ldap.auth("uid=#{username},ou=People,dc=legalbistro,dc=com", password)

          if ldap.bind
            user = AdminUser.where(email: username).first || AdminUser.create!(user_data)
            success!(user)
          else
            fail(:invalid_login)
          end
        end
      end

      def username
        params[:admin_user][:email]
      end

      def password
        params[:admin_user][:password]
      end

      def user_data
        #set default role to ldap
        roles = AdminUser::ROLES[:admin] unless roles.present?
        { email: username, password: password, password_confirmation: password, roles: roles }
      end
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)
