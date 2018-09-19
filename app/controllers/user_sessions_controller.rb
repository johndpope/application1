class UserSessionsController < Devise::SessionsController
  layout false

  def new
    render "users/sessions/new"
  end

  def destroy
    super
  end

  def after_sign_out_path_for(resource)
    shared_media_root_path
  end
end
