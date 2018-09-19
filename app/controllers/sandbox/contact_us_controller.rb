class Sandbox::ContactUsController < Sandbox::BaseController
  include Sandbox::ContactUsHelper
  before_action :authenticate_admin_user!, only: [:listing]
	before_action :set_contact_us, only: [:show, :destroy]
	before_action :init_settings, only: :index

	def index
		@contact_us = Sandbox::ContactUs.new(sandbox_client_id: @sandbox_client.try(:id))
	end

	def create
		@reCaptchaResponse = false

		if params['g-recaptcha-response'].present?
			postData = Net::HTTP.post_form(URI.parse('https://www.google.com/recaptcha/api/siteverify'), { secret: '6LdlUCwUAAAAAENl6AYKWc5hPcuz2ieJnEOz874N', response: params['g-recaptcha-response'] })
			dataJSON = JSON.parse(postData.body)
      puts dataJSON
      @reCaptchaResponse = dataJSON["success"]
			if @reCaptchaResponse
				@contact_us = Sandbox::ContactUs.new(contact_us_params)
				# Tell the ContactUsMailer to send a notifications email after save
				ContactUsMailer.notifications_email if @contact_us.save
			end
		end
	end

	def listing
		params[:limit] = 25 unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'created_at', order_type: 'desc' }
		end

		order_by = if ['client_name'].include?(params[:filter][:order])
			'clients.' + params[:filter][:order].sub('client_', '')
		else
			'sandbox_contact_us.' + params[:filter][:order]
		end

		@contact_us = Sandbox::ContactUs.joins("LEFT OUTER JOIN sandbox_clients ON sandbox_clients.id = sandbox_contact_us.sandbox_client_id LEFT OUTER JOIN clients ON clients.id = sandbox_clients.client_id")
			.by_name(params[:name])
			.by_client_name(params[:client_name])
			.by_email(params[:email])
			.by_phone(params[:phone])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type] + ' NULLS LAST')
			.references(:client)
	end

	def show
		@contact_us = Sandbox::ContactUs.find_by_id(params[:id])

		respond_to do | format |
			format.html { render partial: 'sandbox/contact_us/show' }
			format.json { render json: @contact_us.to_json }
		end
	end

	def read
		@contact_us = Sandbox::ContactUs.find_by_id(params[:id])
		@contact_us.read = params[:status]

		if @contact_us.save
			render json: @contact_us.read.to_json, status: :ok
		else
			render json: @contact_us.errors.to_json, status: :unprocessable_entity
		end
	end

	def destroy
		@contact_us.destroy

		respond_to do | format |
			format.html { redirect_to :back, notice: 'Contact us message was successfully deleted.' }
			format.json { head :no_content }
		end
	end

	def inbox
		@contact_us = Sandbox::ContactUs.where(read: ['false', nil]).order(created_at: :desc)

		if params[:list] == 'true'
			render partial: 'sandbox/contact_us/list', status: :ok
		else
			render json: @contact_us.length.to_json, status: :ok
		end

	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_contact_us
			@contact_us = Sandbox::ContactUs.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def contact_us_params
			params[:sandbox_contact_us].each { | key, value | value.strip! }
			params.require(:sandbox_contact_us).permit!
		end
end
