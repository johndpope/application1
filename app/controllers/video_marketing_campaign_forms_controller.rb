class VideoMarketingCampaignFormsController < ApplicationController
  before_action :set_video_marketing_campaign_form, only: [:show, :edit, :update, :destroy]

  DEFAULT_LIMIT = 25

  # GET /video_marketing_campaign_forms
  # GET /video_marketing_campaign_forms.json
  def index
    params[:limit] = DEFAULT_LIMIT unless params[:limit].present?
    @video_marketing_campaign_forms = VideoMarketingCampaignForm.order(created_at: :desc).page(params[:page]).per(params[:limit])
  end

  # GET /video_marketing_campaign_forms/1
  # GET /video_marketing_campaign_forms/1.json
  def show
  end

  # GET /video_marketing_campaign_forms/1/edit
  def edit
    cities = @video_marketing_campaign_form.cities.present? ? Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (#{@video_marketing_campaign_form.cities.to_s.gsub(/(\[|\])|"/, '')})").order("geobase_regions.name ASC, geobase_localities.name ASC") : []
    @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}"} }
  end

  # PATCH/PUT /video_marketing_campaign_forms/1
  # PATCH/PUT /video_marketing_campaign_forms/1.json
  def update
    cities = @video_marketing_campaign_form.cities.present? ? Geobase::Locality.joins("LEFT OUTER JOIN geobase_regions ON geobase_regions.id = geobase_localities.primary_region_id").where("geobase_localities.id in (#{@video_marketing_campaign_form.cities.to_s.gsub(/(\[|\])|"/, '')})").order("geobase_regions.name ASC, geobase_localities.name ASC") : []
    @cities_json = cities.map { |e| {id: e.id, text: "#{e.name}, #{e.try(:primary_region).try(:code).try(:split, '<sep/>').try(:first).to_s.gsub('US-', '')}"} }
    respond_to do |format|
      if @video_marketing_campaign_form.update(video_marketing_campaign_form_params)
        format.html { redirect_to @video_marketing_campaign_form, notice: 'Video marketing campaign form was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @video_marketing_campaign_form.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /video_marketing_campaign_forms/1
  # DELETE /video_marketing_campaign_forms/1.json
  def destroy
    @video_marketing_campaign_form.destroy
    respond_to do |format|
      format.html { redirect_to video_marketing_campaign_forms_url }
      format.json { head :no_content }
    end
  end

  private
		# Use callbacks to share common setup or constraints between actions.
		def set_video_marketing_campaign_form
			@video_marketing_campaign_form = VideoMarketingCampaignForm.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def video_marketing_campaign_form_params
      brands = params[:video_marketing_campaign_form][:brands].to_a.uniq
      brands.delete("0")
      params[:video_marketing_campaign_form][:brands] = brands
      params[:video_marketing_campaign_form][:tag_list] = sanitize_tags(params[:video_marketing_campaign_form][:tag_list])
			params.require(:video_marketing_campaign_form).permit!
		end

    def sanitize_tags(tags)
      tags.to_s.split(',').reject(&:blank?).map{|e|e.to_s.mb_chars.downcase.to_s}.uniq
    end
end
