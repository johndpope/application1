json.array!(@video_marketing_campaign_forms) do |video_marketing_campaign_form|
  json.extract! video_marketing_campaign_form, :id
  json.url video_marketing_campaign_form_url(video_marketing_campaign_form, format: :json)
end
