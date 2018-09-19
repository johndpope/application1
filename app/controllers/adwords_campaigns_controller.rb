class AdwordsCampaignsController < ApplicationController
  before_action :set_adwords_campaign, only: [:show, :edit, :update, :destroy, :set]

  def index
    @adwords_campaigns = AdwordsCampaign.all
  end

  def show
  end

  def new
    @adwords_campaign = AdwordsCampaign.new(networks_youtube_search: true, networks_youtube_videos: true, networks_include_video_partners: true, campaign_type: AdwordsCampaign.campaign_type.find_value('Video'))
		if params[:email_account_id].present?
			@email_account = EmailAccount.find(params[:email_account_id])
			@adwords_campaign.google_account_id = @email_account.email_item_id
		end
  end

  def edit
  end

  def create
    @adwords_campaign = AdwordsCampaign.new(adwords_campaign_params)
		if @adwords_campaign.campaign_type != AdwordsCampaign.campaign_type.find_value('Video')
			@adwords_campaign.campaign_subtype = nil
		end
		@email_account = EmailAccount.find(params[:email_account_id])

    respond_to do |format|
      if @adwords_campaign.save
        format.html { redirect_to edit_email_account_path(params[:email_account_id], :anchor => "adwords-campaigns-tab"), notice: 'Adwords campaign was successfully created.' }
        format.json { render action: 'show', status: :created, location: @adwords_campaign }
      else
        format.html { render action: 'new' }
        format.json { render json: @adwords_campaign.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
		adwords_campaign_params_hash = adwords_campaign_params
		if adwords_campaign_params_hash[:campaign_type] != AdwordsCampaign.campaign_type.find_value('Video').value.to_s
			adwords_campaign_params_hash[:campaign_subtype] = nil
		end
    respond_to do |format|
      if @adwords_campaign.update(adwords_campaign_params_hash)
        format.html { redirect_to edit_email_account_path(params[:email_account_id], :anchor => "adwords-campaigns-tab"), notice: 'Adwords campaign was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @adwords_campaign.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @adwords_campaign.destroy
    respond_to do |format|
      format.html { redirect_to edit_email_account_path(params[:email_account_id], :anchor => "adwords-campaigns-tab") }
      format.json { head :no_content }
    end
  end

	def set
    @adwords_campaign.linked = params[:linked] if params[:linked].present?
    response = if @adwords_campaign.save
      @adwords_campaign.add_posting_time if params[:linked].present?
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_adwords_campaign
			@adwords_campaign = AdwordsCampaign.find(params[:id])
			@email_account = EmailAccount.find(params[:email_account_id])
			@adwords_campaign_groups = @adwords_campaign.try(:adwords_campaign_groups).try(:sort)
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def adwords_campaign_params
			#temporary, need to fix
			%w(start_date end_date).each do |field|
				params[:adwords_campaign][field] = Date.strptime(params[:adwords_campaign][field], '%m/%d/%Y') if params[:adwords_campaign][field].present? && (params[:adwords_campaign][field].is_a? String)
			end
			params[:adwords_campaign][:languages] = params[:adwords_campaign][:languages].reject { |c| c.empty? }
			params[:adwords_campaign][:languages] = params[:adwords_campaign][:languages].join(",") if (params[:adwords_campaign][:languages].is_a? Array)
		 params.require(:adwords_campaign).permit!
		end
end
