class Users::SessionsController < ApplicationController
  layout false

  def destroy
    super
  end

  def after_sign_out_path_for(resource)
    shared_media_root_path
  end
end
