class AdwordsCampaignGroupsController < ApplicationController
  before_action :set_adwords_campaign_group, only: [:show, :edit, :update, :destroy, :set]

  def index
    @adwords_campaign_groups = AdwordsCampaignGroup.all
  end

  def show
  end

  def new
    @adwords_campaign_group = AdwordsCampaignGroup.new(video_ad_format: AdwordsCampaignGroup.video_ad_format.find_value('In-display ad'))
		if params[:adwords_campaign_id].present?
			@adwords_campaign = AdwordsCampaign.find(params[:adwords_campaign_id])
			@email_account = @adwords_campaign.google_account.email_account
			@adwords_campaign_group.adwords_campaign_id = params[:adwords_campaign_id]
		end
  end

  def edit
  end

  def create
    @adwords_campaign_group = AdwordsCampaignGroup.new(adwords_campaign_group_params)
		@adwords_campaign = AdwordsCampaign.find(params[:adwords_campaign_id])
		@email_account = @adwords_campaign.google_account.email_account
    respond_to do |format|
      if @adwords_campaign_group.save
        format.html { redirect_to edit_email_account_adwords_campaign_path(@email_account, @adwords_campaign, :anchor => "adwords-campaign-groups-tab"), notice: 'Adwords campaign group was successfully created.' }
        format.json { render action: 'show', status: :created, location: @adwords_campaign_group }
      else
        format.html { render action: 'new' }
        format.json { render json: @adwords_campaign_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @adwords_campaign_group.update(adwords_campaign_group_params)
        format.html { redirect_to edit_email_account_adwords_campaign_path(@email_account, @adwords_campaign, :anchor => "adwords-campaign-groups-tab"), notice: 'Adwords campaign group was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @adwords_campaign_group.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @adwords_campaign_group.destroy
    respond_to do |format|
      format.html { redirect_to edit_email_account_adwords_campaign_path(@email_account, @adwords_campaign, :anchor => "adwords-campaign-groups-tab") }
      format.json { head :no_content }
    end
  end

  def set
    @adwords_campaign_group.linked = params[:linked] if params[:linked].present?
    response = if @adwords_campaign_group.save
      @adwords_campaign_group.add_posting_time if params[:linked].present?
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_adwords_campaign_group
			@adwords_campaign_group = AdwordsCampaignGroup.find(params[:id])
			@adwords_campaign = AdwordsCampaign.find(params[:adwords_campaign_id])
			@email_account = @adwords_campaign.google_account.email_account
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def adwords_campaign_group_params
		 params.require(:adwords_campaign_group).permit!
		end
end
