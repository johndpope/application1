class RepresentativesController < ApplicationController
  before_action :set_representative, only: [:show, :edit, :update, :destroy]

  def index
    @representatives = if params[:client_id].present?
      @client = Client.find(params[:client_id].to_i)
      Representative.where("client_id = ?", params[:client_id].to_i)
    else
      Representative.all
    end
  end

  def show
  end

  def new
    @representative = if params[:client_id].present? || params[:representative][:client_id].present?
      client_id = params[:client_id] || params[:representative][:client_id]
      @client = Client.find(client_id.to_i)
      Representative.new(client_id: client_id.to_i)
    else
      Representative.new
    end
  end

  def edit
    @client = @representative.client
  end

  def create
    products_params = representative_params[:products]
    representative_params.delete(:products)
    @representative = Representative.new(representative_params)
    product_ids = products_params.to_a.reject(&:empty?).map(&:to_i)

    respond_to do |format|
      if @representative.save
        @representative.products = if product_ids.present?
          Product.where("id in (?)", product_ids)
        else
          []
        end
        @representative.save
        format.html { redirect_to new_client_contract_path(client_id: @representative.client.id), notice: 'Representative was successfully created.' }
        format.json { render action: 'show', status: :created, location: @representative }
      else
        params[:products] = product_ids
        @client = Client.find(@representative.client_id)
        format.html { render action: 'new'}
        format.json { render json: @representative.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @representative.update(representative_params)
        format.html { redirect_to client_representatives_path(client_id: @representative.client.id), notice: 'Representative was successfully updated.' }
        format.json { head :no_content }
      else
        @client = Client.find(@representative.client_id)
        format.html { render action: 'edit' }
        format.json { render json: @representative.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @representative.destroy
    respond_to do |format|
      format.html { redirect_to client_representatives_path(client_id: @representative.client.id) }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_representative
      @representative = Representative.find(params[:id])
      if params[:representative].present?
        product_ids = params[:representative][:products].to_a.reject(&:empty?).map(&:to_i)
        @representative.products = if product_ids.present?
          Product.where("id in (?)", product_ids)
        else
          []
        end
      end
      @representative
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def representative_params
      prms = params.require(:representative).permit!
      prms.delete(:products) if params[:representative].present? && params[:action] != 'create'
      prms
    end
end
