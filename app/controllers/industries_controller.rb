class IndustriesController < ApplicationController
  before_action :set_industry, only: [:show, :edit, :update]
  INDUSTRY_DEFAULT_LIMIT = 25

  def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "code"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "asc"
      end
    else
      params[:filter] = {order: "code", order_type: "asc" }
    end
    order_by = 'industries.'
    order_by += params[:filter][:order]
    params[:limit] = INDUSTRY_DEFAULT_LIMIT unless params[:limit].present?
    @industries = Industry.all
    .by_id(params[:id])
    .by_code(params[:code])
    .page(params[:page]).per(params[:limit])
    .order(order_by + ' ' + params[:filter][:order_type] + ' NULLS LAST')
  end

  def show
    respond_to do |format|
      format.json { render json: @industry.json }
    end
  end

  # GET /industries/1/edit
	def edit
		respond_to do |format|
			format.js
		end
	end

	# POST /industries
	# POST /industries.json
	def create
		@industry = Industry.new(industry_params)
		if @industry.save
			render :create, locals: { industry: @industry }
		else
			render :new, locals: { industry: @industry }
		end
	end

	# PATCH/PUT /industries/1
	# PATCH/PUT /industries/1.json
	def update
		@industry.update_attributes(industry_params)
		if @industry.save
			render :update, locals: {industry: @industry}
		else
			render :edit, locals: {industry: @industry}
		end
	end

	def json_list
		@industries = if params[:id].present? && !params[:q].present?
			Industry.where('id = ?', params[:id])
		else
			Industry.by_code_or_name(params[:q])
		end
    #json = if params[:id].present? || (params[:q].present? && !(true if Float(params[:q]) rescue false))
    #json = if params[:id].present?
    json = if params[:id].present? && !params[:q].present?
      @industries.map { |i|
        {
          id: i.id,
          text: i.display_name,
          children: i.children.map { |c1|
            {
              id: c1.id,
              text: c1.display_name,
              parent: i.id,
              children: c1.children.map { |c2|
                {
                  id: c2.id,
                  text: c2.display_name,
                  parent: c1.id,
                  children: c2.children.map { |c3|
                    {
                      id: c3.id,
                      text: c3.display_name,
                      parent: c2.id,
                      children: c3.children.map { |c4|
                        {
                          id: c4.id,
                          text: c4.display_name,
                          parent: c3.id
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    else
      @industries.map { |i|
        {
          id: i.id,
          text: i.display_name
        }
      }
    end
		render json: json
	end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_industry
      @industry = Industry.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def industry_params
      params[:industry][:nickname] = nil if params[:industry] && !params[:industry][:nickname].present?
      %w(channel video).each do |type|
        params[:industry][:"business_#{type}_title_patterns"] = [] if (params[:industry][:"business_#{type}_title_patterns"].is_a? Array) && !params[:industry][:"business_#{type}_title_patterns"].reject(&:empty?).present?
        params[:industry][:"business_#{type}_title_patterns"] = params[:industry][:"business_#{type}_title_patterns"].reject(&:empty?) if (params[:industry][:"business_#{type}_title_patterns"].is_a? Array) && params[:industry][:"business_#{type}_title_patterns"].reject(&:empty?).present?
      end
      params.require(:industry).permit!
    end
end
