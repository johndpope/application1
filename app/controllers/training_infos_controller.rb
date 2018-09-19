class TrainingInfosController < ApplicationController
	before_action :set_training_info, only: [:show, :edit, :update, :destroy]
	skip_before_filter :authenticate_admin_user!, :only => [:show]

	def index
		if params[:group_name].present?
			@training_infos = TrainingInfo.by_group_name(params[:group_name]).order(created_at: :desc)
		end
	end

	def show
	end

	def new
		@training_info = TrainingInfo.new
	end

	def edit
	end

	def create
		@training_info = TrainingInfo.new(training_info_params)
		@training_info.admin_user = current_admin_user if current_admin_user.present?

		respond_to do |format|
	      if @training_info.save
	        format.html { redirect_to training_infos_path, notice: 'Training info was successfully created.' }
	        format.json { render action: 'show', status: :created, location: @training_info }
	      else
	        format.html { render action: 'new' }
	        format.json { render json: @training_info.errors, status: :unprocessable_entity }
	      end
	    end

	end

	def update
		respond_to do |format|
			if @training_info.update(training_info_params)
				format.html { redirect_to training_infos_path, notice: 'Training info was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @training_info.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
		@training_info.destroy

		respond_to do |format|
			format.html { redirect_to :back, notice: 'Training info was successfully deleted.' }
			format.json { head :no_content }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_training_info
			@training_info = TrainingInfo.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def training_info_params
			#temporary, need to fix
			%w(recorded_at).each do |field|
				params[:training_info][field] = DateTime.strptime(params[:training_info][field], '%m/%d/%Y') if params[:training_info][field].present?
			end
			params.require(:training_info).permit!
		end
end
