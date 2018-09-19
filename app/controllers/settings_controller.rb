class SettingsController < ApplicationController
	before_action :set_setting, only: [:edit, :update, :destroy]

	# GET /settings
	# GET /settings.json
	def index
		@settings = Setting.order(name: :asc)
	end

	# GET /settings/new
	def new
		@setting = Setting.new

		respond_to do |format|
			format.js
		end
	end

	# GET /settings/1/edit
	def edit
		respond_to do |format|
			format.js
		end
	end

	# POST /settings
	# POST /settings.json
	def create
		@setting = Setting.new(setting_params)
		if @setting.save
			render :create, locals: { setting: @setting }
		else
			render :new, locals: { setting: @setting }
		end
	end

	# PATCH/PUT /settings/1
	# PATCH/PUT /settings/1.json
	def update
		@setting.update_attributes(setting_params)
		if @setting.save
			render :update, locals: {setting: @setting}
		else
			render :edit, locals: {setting: @setting}
		end
	end

	# DELETE /settings/1
	# DELETE /settings/1.json
	def destroy
		@setting.destroy
		respond_to do |format|
			format.js
		end
	end

  def fetch_value
    response = if params[:field].present?
      Setting.get_value_by_name(params[:field]) || {status: 404}
    else
      {status: 500}
    end
    render json: response
  end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_setting
			@setting = Setting.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def setting_params
			params[:setting].each { |key, value| value.strip! }
			params.require(:setting).permit!
		end
end
