class Invoice < ActiveRecord::Base
  include Reversible
  belongs_to :client
  has_many :invoice_items, dependent: :destroy
  validates :invoice_id, :invoice_number, :currency_code, :payment_terms, :merchant_email, :payer_email, :client_id, presence: true
  DOWN_PAYMENT_INVOICING_ENABLED = true
  AUTOMATIC_INVOICING_ENABLED = true

  def update_info
    if self.invoice_id.present?
      get_invoice_details_response = PayPalService.get_invoice_details(self.invoice_id)
      if get_invoice_details_response.success?
        self.status = get_invoice_details_response.invoiceDetails.status
        self.total_amount = get_invoice_details_response.invoiceDetails.totalAmount.to_f
        self.first_sent_date = get_invoice_details_response.invoiceDetails.firstSentDate
        self.last_sent_date = get_invoice_details_response.invoiceDetails.lastSentDate
        self.last_updated_date = get_invoice_details_response.invoiceDetails.lastUpdatedDate
        self.save
        true
      end
    end
  end

  class << self
    def by_id(id)
      return all unless id.present?
      where("invoices.id = ?", id.strip)
    end

    def by_invoice_number(invoice_number)
      return all unless invoice_number.present?
      where("invoices.invoice_number = ?", invoice_number.strip)
    end

    def by_invoice_id(invoice_id)
      return all unless invoice_id.present?
      where("LOWER(invoices.invoice_id) LIKE ?", "%#{invoice_id.downcase.strip}%")
    end

    def by_client_id(client_id)
  		return all unless client_id.present?
  		where('clients.id = ?', client_id)
  	end

    def by_status(status)
      return all unless status.present?
  		where('invoices.status = ?', status)
    end

    def by_payment_terms(payment_terms)
      return all unless payment_terms.present?
  		where('invoices.payment_terms = ?', payment_terms)
    end
  end

end
