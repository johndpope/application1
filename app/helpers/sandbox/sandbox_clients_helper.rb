module Sandbox::SandboxClientsHelper
	def build_video_campaign_map(client, locality, include_details = false)
		res = {
			locality: locality,
			locality_details: Sandbox::LocalityDetails.find_by_locality_id(locality.id)
		}

		return res unless include_details

		campaign_video_stages = Sandbox::VideoCampaignVideoStage.joins(:video_campaign).where('locality_id = ? and sandbox_client_id = ?', locality.id, client.id)
		res[:months_count] = campaign_video_stages.max_by { | cvs | cvs.month_nr }.month_nr
		res[:video_campaigns] = client.video_campaigns.order(:order_nr)

		timeline = Array.new(res[:months_count]) { Array.new(res[:video_campaigns].size, nil) }
		res[:months_of_new_videos] = {}

		0.upto(res[:video_campaigns].size - 1) do | s |
			cvs = res[:video_campaigns][s].campaign_video_stages.where(locality_id: locality.id).order(:month_nr)
			res[:months_of_new_videos][res[:video_campaigns][s].id] = cvs.first.month_nr unless cvs.first.blank?

			0.upto(res[:months_count] -1) do | m |
				campaign_video_stage = cvs.select { | v | v.month_nr == m + 1 }.first
				timeline[m][s] = campaign_video_stage unless campaign_video_stage.nil?
			end
		end

		res[:timeline] = timeline

		return res
	end
end
