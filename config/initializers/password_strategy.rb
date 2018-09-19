module Devise
  module Strategies
    class Password < Base
      def authenticate!
        if params[:admin_user]
          user = AdminUser.where(email: params[:admin_user][:email]).first
          if user.present? && user.valid_password?(params[:admin_user][:password])
            success!(user)
          else
            fail(:invalid_login)
          end
        end
      end
    end
  end
end
