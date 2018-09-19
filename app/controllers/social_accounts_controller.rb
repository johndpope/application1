class SocialAccountsController < ApplicationController
	before_action :set_social_account, only: [:edit, :update, :destroy]
	SOCIAL_ACCOUNTS_DEFAULT_LIMIT = 25

	def index
		params[:limit] = SOCIAL_ACCOUNTS_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end

		order_by = params[:filter][:order]

		@social_accounts = SocialAccount.all
			.by_id(params[:id])
			.by_social_item_id(params[:social_item_id])
			.by_social_item_type(params[:social_item_type])
      .by_account_type(params[:account_type])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type])
	end

	def new
		@social_account = SocialAccount.new
	end

	def edit
	end

	def create
		@social_account = SocialAccount.new(social_account_params)

		respond_to do |format|
			if @social_account.save
				format.html { redirect_to social_accounts_path, notice: 'Social account was successfully created.' }
				format.json { render action: 'index', status: :created, location: @social_account }
			else
				format.html { render action: 'new' }
				format.json { render json: @social_account.errors, status: :unprocessable_entity }
			end
		end
	end

	def update
		respond_to do |format|
			if @social_account.update(social_account_params)
				format.html { redirect_to social_accounts_path, notice: 'Social account was successfully updated.' }
				format.json { head :no_content }
			else
				format.html { render action: 'edit' }
				format.json { render json: @social_account.errors, status: :unprocessable_entity }
			end
		end
	end

	def destroy
    #change to @social_account.destroy after creating a hook
		@social_account.social_item.destroy

		respond_to do |format|
			format.html { redirect_to social_accounts_url, notice: 'Social account was successfully deleted.' }
			format.json { head :no_content }
		end
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_social_account
			@social_account = SocialAccount.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def social_account_params
			params.require(:social_account).permit!
		end
end
