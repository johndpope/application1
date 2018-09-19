module Sandbox::ContactUsHelper
	def init_settings
		@sandbox_client = Sandbox::Client.find_by_uuid!(params[:client_uuid]) if params[:client_uuid].present?
	end
end
