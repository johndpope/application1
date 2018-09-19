class SentEmailsController < ApplicationController
	# GET /sent_emails
	# GET /sent_emails.json
	def index
		@sent_emails = SentEmail.order(name: :asc)
	end

	# GET /sent_emails/new
	def new
		@sent_email = SentEmail.new(sender: "no-reply@echovideoblender.com", subject: params[:subject], resource_id: params[:resource_id], resource_type: params[:resource_type])
    receiver = if @sent_email.resource_type == 'Dealer'
      resource = Object.const_get(params[:resource_type]).find(params[:resource_id].to_i)
      industry_id = resource.try(:client).try(:industry_id) || resource.try(:industry_id)

      sandbox_client = Sandbox::Client.joins(:client).where("clients.id = ?", resource.client_id).order("sandbox_clients.created_at ASC").first || Sandbox::Client.joins(:client).where("clients.industry_id = ?", industry_id).order("sandbox_clients.created_at ASC").first
      if params[:type] == "follow_up_call"
        @sent_email.body = render_to_string 'broadcaster_mailer/dealer_follow_up_call', layout: false, locals: {dealer: resource, sandbox_client: sandbox_client}
      end
      [resource.try(:email), resource.contact_people.map(&:email)].flatten.compact.reject(&:blank?).join(",")
    else
      params[:receiver]
    end
    @sent_email.receiver = receiver

		respond_to do |format|
			format.js
		end
	end

	# POST /sent_emails
	# POST /sent_emails.json
	def create
		@sent_email = SentEmail.new(sent_email_params)
    @sent_email.admin_user = current_admin_user
		if @sent_email.save
      BroadcasterMailer.custom_mail(@sent_email.receiver, @sent_email.subject, @sent_email.body)
			render :create, locals: { sent_email: @sent_email }
		else
			render :new, locals: { sent_email: @sent_email }
		end
	end


	private
		# Use callbacks to share common setup or constraints between actions.
		def set_sent_email
			@sent_email = SentEmail.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def sent_email_params
			params[:sent_email].each { |key, value| value.strip! }
      params[:sent_email][:resource_id] = params[:resource_id] if params[:resource_id]
      params[:sent_email][:resource_type] = params[:resource_type] if params[:resource_type]
			params.require(:sent_email).permit!
		end
end
