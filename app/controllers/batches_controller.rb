class BatchesController < ApplicationController
	before_action :set_batch, only: [:edit, :update, :destroy, :refresh]

	# GET /batches
	# GET /batches.json
	def index
		@batches = Batch.order(updated_at: :desc)
	end

	# GET /batches/new
	def new
		@batch = Batch.new

		respond_to do |format|
			format.js
		end
	end

	# GET /batches/1/edit
	def edit
		respond_to do |format|
			format.js
		end
	end

	# POST /batches
	# POST /batches.json
	def create
		@batch = Batch.new(batch_params)
		if @batch.save
			render :create, locals: { batch: @batch }
		else
			render :new, locals: { batch: @batch }
		end
	end

	# PATCH/PUT /batches/1
	# PATCH/PUT /batches/1.json
	def update
		@batch.update_attributes(batch_params)
		if @batch.save
			render :update, locals: {batch: @batch}
		else
			render :edit, locals: {batch: @batch}
		end
	end

	def refresh
		@batch.email_account_ids = @batch.execute_query.join(",")
		if @batch.save
			render :refresh, locals: {batch: @batch, successfully_executed: true}
		else
			render :refresh, locals: {batch: @batch, successfully_executed: false}
		end
	end

	# DELETE /batches/1
	# DELETE /batches/1.json
	def destroy
		@batch.destroy
		respond_to do |format|
			format.js
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_batch
			@batch = Batch.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def batch_params
			params[:batch].each { |key, value| value.strip! }
			params.require(:batch).permit!
		end
end
