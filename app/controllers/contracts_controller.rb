class ContractsController < ApplicationController
  before_action :set_contract, only: [:show, :edit, :update, :destroy, :send_down_payment_invoice]

  # GET /contracts
  # GET /contracts.json
  def index
    @contracts = if params[:client_id].present?
      @client = Client.find(params[:client_id].to_i)
      Contract.where("client_id = ?", params[:client_id].to_i)
    else
      Contract.all
    end
  end

  # GET /contracts/1
  # GET /contracts/1.json
  def show
  end

  # GET /contracts/new
  def new
    @contract = if params[:client_id].present? || params[:contract][:client_id].present?
      client_id = params[:client_id] || params[:contract][:client_id]
      @client = Client.find(client_id.to_i)
      @contracts = Contract.where(client_id: client_id.to_i)
      Contract.new(client_id: client_id.to_i)
    else
      @contracts = Contract.all
      Contract.new
    end
  end

  # GET /contracts/1/edit
  def edit
    @client = @contract.client
    @contracts = Contract.where("id <> ? AND client_id = ?", @contract.id, @contract.client_id)
  end

  # POST /contracts
  # POST /contracts.json
  def create
    products_params = contract_params[:products]
    contract_params.delete(:products)
    @contract = Contract.new(contract_params)

    respond_to do |format|
      if @contract.save
        product_ids = products_params.to_a.reject(&:empty?).map(&:to_i)
        @contract.products = if product_ids.present?
          Product.where("id in (?)", product_ids)
        else
          []
        end
        if @contract.save
          format.html { redirect_to new_client_email_accounts_setup_path(client_id: @contract.client.id, contract_id: @contract.id), notice: 'Contract was successfully created.' }
          format.json { render action: 'show', status: :created, location: @contract }
        else
          @client = Client.find(@contract.client_id)
          @contracts = Contract.where(client_id: @contract.client_id)
          format.html { render action: 'edit' }
          format.json { render json: @contract.errors, status: :unprocessable_entity }
        end
      else
        @client = Client.find(@contract.client_id)
        @contracts = Contract.where(client_id: @contract.client_id)
        format.html { render action: 'new' }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contracts/1
  # PATCH/PUT /contracts/1.json
  def update
    respond_to do |format|
      if @contract.update(contract_params)
        format.html { redirect_to client_contracts_path(client_id: @contract.client_id), notice: 'Contract was successfully updated.' }
        format.json { head :no_content }
      else
        @contracts = Contract.where("id <> ? AND client_id = ?", @contract.id, @contract.client_id)
        @client = Client.find(@contract.client_id)
        format.html { render action: 'edit' }
        format.json { render json: @contract.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contracts/1
  # DELETE /contracts/1.json
  def destroy
    @contract.destroy
    respond_to do |format|
      format.html { redirect_to client_contracts_path(client_id: @contract.client_id) }
      format.json { head :no_content }
    end
  end

  def send_down_payment_invoice
    notice_message = nil
    alert_message = nil
    if !@contract.has_down_payment_items? && @contract.client.pay_pal_email.present? && @contract.payment_amount.to_i > 0 && @contract.down_payment.to_i > 0
      description = @contract.down_payment == @contract.payment_amount ? "" : "Down payment"
      items_array = []
      items_array << {:name => "Echo Video Blender - Contract ##{@contract.id}", :quantity => 1.0, :unit_price => @contract.down_payment, :description => description}
      invoice = @contract.create_invoice(items_array, InvoiceItem.invoice_item_type.find_value(:down_payment).value)
      if invoice.present?
        invoice.update_info
        send_invoice_response = PayPalService.send_invoice(invoice.invoice_id)
        if send_invoice_response.success?
          notice_message = 'Down payment invoice was successfully created and sent!'
          invoice.update_info
        else
          notice_message = nil
          alert_message = 'Down payment invoice was created, but failed to send'
        end
      else
        alert_message = 'Down payment invoice was not created!'
      end
    else
      alert_message = 'Down payment invoice was already sent!'
    end
    respond_to do |format|
      format.html { redirect_to client_contracts_path(client_id: @contract.client_id), notice: notice_message, alert: alert_message }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contract
      @contract = Contract.find(params[:id])
      if params[:contract].present?
        product_ids = params[:contract][:products].to_a.reject(&:empty?).map(&:to_i)
        ap product_ids
        @contract.products = if product_ids.present?
          Product.where("id in (?)", product_ids)
        else
          []
        end
      end
      @contract
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def contract_params
      #temporary, need to fix
      %w(execution_date start_date end_date video_posting_start_date video_posting_end_date amendment_date client_subject_video_supply_date).each do |field|
        params[:contract][field] = DateTime.strptime(params[:contract][field], '%m/%d/%Y') if params[:contract][field].present?
      end
      prms = params.require(:contract).permit!
      prms.delete(:products) if params[:contract].present? && params[:action] != 'create'
      prms
    end
end
