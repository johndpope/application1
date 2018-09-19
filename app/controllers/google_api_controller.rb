require 'google/api_client'

class GoogleApiController < ApplicationController

  def authenticate
    google_account = GoogleAccount.find(params[:google_account_id])

    client = Google::APIClient.new
    client.authorization.client_id = google_account.google_api_client.client_id
    client.authorization.client_secret = google_account.google_api_client.client_secret
    client.authorization.redirect_uri = google_api_callback_url
    client.authorization.scope = Rails.application.config.google_api[:scopes]
    session[:google_account_id] = params[:google_account_id]
    redirect_to client.authorization.authorization_uri.to_s
  end

  def callback
    google_account = GoogleAccount.find(session[:google_account_id])

    client = Google::APIClient.new
    client.authorization.client_id = google_account.google_api_client.client_id
    client.authorization.client_secret = google_account.google_api_client.client_secret
    client.authorization.redirect_uri = google_api_callback_url
    client.authorization.scope = Rails.application.config.google_api[:scopes]
    client.authorization.code = params[:code]
    client.authorization.fetch_access_token!

    session[:google_account_id] = nil
    google_account.update_attribute(:refresh_token, client.authorization.refresh_token)
    redirect_to admin_google_account_path(google_account), notice: 'You have successfully obtained refresh token'
  end
end
