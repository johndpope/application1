class DomainsController < ApplicationController
	before_action :set_domain, only: [:edit, :update, :destroy]
	DOMAINS_DEFAULT_LIMIT = 25

	def index
		params[:limit] = DOMAINS_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end

		order_by = params[:filter][:order]

		@domains = Domain.all
			.by_id(params[:id])
			.by_name(params[:name])
      .by_parked(params[:parked])
			.page(params[:page]).per(params[:limit])
			.order(order_by + ' ' + params[:filter][:order_type])
	end

	def new
		@domain = Domain.new
    render :edit, locals: {domain: @domain}
	end

  def edit
    render :edit, locals: {domain: @domain}
  end

  def update
    if @domain.update_attributes(domain_params)
      render :update, locals: {domain: @domain}
    else
      render :edit, locals: {domain: @domain}
    end
  end

	def create
		@domain = Domain.new(domain_params)
    if @domain.save
      render :create, locals: {domain: @domain}
    else
      render :new, locals: {domain: @domain}
    end
	end

	def destroy
		@domain.destroy
    render :destroy, locals: {domain: @domain}
	end

	private
		# Use callbacks to share common setup or constraints between actions.
		def set_domain
			@domain = Domain.find(params[:id])
		end

		# Never trust parameters from the scary internet, only allow the white list through.
		def domain_params
			prms = params.require(:domain).permit!
      prms[:name] = prms[:name].strip
      prms
		end
end
