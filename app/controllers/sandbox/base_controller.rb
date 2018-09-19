class Sandbox::BaseController < ActionController::Base
  before_filter :detect_profile
	include DataPage
	layout 'sandbox'

  def detect_profile
    @video_marketing_campaign_form_public_profile_uuid = request.cookies["video_marketing_campaign_form_public_profile_uuid"]
    @video_marketing_campaign_form_id = request.cookies["video_marketing_campaign_form_id"]
  end
end
