class OmniauthCallbacksController < Devise::OmniauthCallbacksController

  %w(facebook google_oauth2 twitter).each do |sn|
    define_method sn do
      @user = User.find_for_oauth(request.env["omniauth.auth"], current_user)
      if !@user.blank? && @user.persisted?
        flash.notice = "You are successfully signed in with #{sn.humanize}"
        sign_in_and_redirect @user, :event => :authentication
      else
        session["devise.user_attributes"] = @user.attributes
        redirect_to shared_media_root_path
      end
    end
  end

  def passthru
    redirect_to shared_media_root_path, :notice => "provider authentication error"
  end

  def after_sign_in_path_for(resource)
    shared_media_images_local_import_path
  end

end
