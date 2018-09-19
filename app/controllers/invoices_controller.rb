class InvoicesController < ApplicationController
  before_action :set_invoice, only: [:show, :edit, :update, :destroy, :send_invoice, :cancel_invoice, :legend]
  INVOICE_DEFAULT_LIMIT = 25

  # GET /invoices
  # GET /invoices.json
  def index
    if params[:filter].present?
      unless params[:filter][:order].present?
        params[:filter][:order] = "id"
      end
      unless params[:filter][:order_type].present?
        params[:filter][:order_type] = "desc"
      end
    else
      params[:filter] = {order: "id", order_type: "desc" }
    end
    order_by = 'invoices.'
    if params[:filter][:order] == 'client'
      order_by = 'clients.name'
    else
      order_by += params[:filter][:order]
    end
    params[:limit] = INVOICE_DEFAULT_LIMIT unless params[:limit].present?
    @invoices = Invoice.joins("LEFT JOIN clients ON clients.id = invoices.client_id")
    .by_id(params[:id])
    .by_invoice_number(params[:invoice_number])
    .by_invoice_id(params[:invoice_id])
    .by_status(params[:status])
    .by_payment_terms(params[:payment_terms])
    .by_client_id(params[:client_id])
    .page(params[:page]).per(params[:limit])
    .order(order_by + ' ' + params[:filter][:order_type])
  end

  # GET /invoices/1
  # GET /invoices/1.json
  def show
  end

  # GET /invoices/new
  def new
    @invoice = Invoice.new
  end

  # GET /invoices/1/edit
  def edit
  end

  # POST /invoices
  # POST /invoices.json
  def create
    @invoice = Invoice.new(invoice_params)

    respond_to do |format|
      if @invoice.save
        format.html { redirect_to @invoice, notice: 'Invoice was successfully created.' }
        format.json { render action: 'show', status: :created, location: @invoice }
      else
        format.html { render action: 'new' }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invoices/1
  # PATCH/PUT /invoices/1.json
  def update
    respond_to do |format|
      if @invoice.update(invoice_params)
        format.html { redirect_to @invoice, notice: 'Invoice was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @invoice.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invoices/1
  # DELETE /invoices/1.json
  def destroy
    @invoice.destroy
    respond_to do |format|
      format.html { redirect_to invoices_url }
      format.json { head :no_content }
    end
  end

  def send_invoice
    notice_message = nil
    alert_message = nil
    send_invoice_response = PayPalService.send_invoice(@invoice.invoice_id)

    if send_invoice_response.success?
      notice_message = "Invoice ##{@invoice.id} was successfully sent!"
      @invoice.update_info
    else
      alert_message = "Invoice ##{@invoice.id} failed to send!"
    end
    respond_to do |format|
      format.html { redirect_to invoices_url, notice: notice_message, alert: alert_message }
      format.json { head :no_content }
    end
  end

  def cancel_invoice
    notice_message = nil
    alert_message = nil
    cancel_invoice_response = PayPalService.cancel_invoice(@invoice.invoice_id)
    if cancel_invoice_response.success?
      notice_message = "Invoice ##{@invoice.id} was successfully canceled!"
      @invoice.update_info
    else
      alert_message = "Invoice ##{@invoice.id} failed to cancel!"
    end
    respond_to do |format|
      format.html { redirect_to invoices_url, notice: notice_message, alert: alert_message }
      format.json { head :no_content }
    end
  end

  def legend
		respond_to do |format|
			format.html { render 'legend', layout: false, locals: { invoice: @invoice } }
		end
	end

  def update_invoices_info
    PayPalService.update_invoices_info
    respond_to do |format|
      format.html { redirect_to invoices_url, notice: "All invoices info was updated successfully." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_invoice
      @invoice = Invoice.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def invoice_params
      params.require(:invoice).permit!
    end
end
