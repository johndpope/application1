class Contract < ActiveRecord::Base
  include Reversible
  has_and_belongs_to_many :products
  belongs_to :client
  belongs_to :parent, class_name: 'Contract', foreign_key: :parent_id
  has_many :invoice_items, as: :resource, dependent: :destroy
  has_one :email_accounts_setup
  validates :client_id, presence: :true
  validates :products, presence: true, if: :persisted?
  validates :payment_amount, :down_payment, :payment_duration, :payment_frequency, presence: true, if: :automatic_invoices_enabled?
  validate :payment_amount_and_down_payment

  attr_accessor :contract_document
  has_attached_file :contract_document, path: ':rails_root/public/system/contracts/:id/contract_document/:basename.:extension', url:  '/system/contracts/:id/contract_document/:basename.:extension'
  validates_attachment_content_type :contract_document, content_type: [
      'application/msword',
      'application/pdf',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'application/zip',
      'application/vnd.ms-excel',
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'text/plain']

  PAYMENT_FREQUENCIES = {"Monthly"=>1, "Quarterly"=>3, "Biannually"=>6, "Yearly"=>12}

  def display_name
    "Contract ##{self.id} | Products: #{self.try(:products).to_a.map(&:name).join(', ')}"
  end

  def create_invoice(items_array, invoice_item_type = InvoiceItem.invoice_item_type.find_value(:other).value)
    paypal_logger = PayPalService.paypal_logger
    paypal_logger.info("------------------------------------------------------")
    paypal_logger.info("Contract ##{self.id} | Client ##{self.client_id}")
    params = {
      :merchantEmail => CONFIG['paypal']['merchant_email'],
      :payerEmail => self.client.pay_pal_email,
      :itemList => {:item => items_array },
      :currencyCode => "USD",
      :paymentTerms => "DueOnReceipt" }
    create_invoice_response = PayPalService.create_invoice(params)
    if create_invoice_response.success?
      invoice = Invoice.create(invoice_id: create_invoice_response.invoiceID, invoice_number: create_invoice_response.invoiceNumber, currency_code: params[:currencyCode], payment_terms: params[:paymentTerms], merchant_email: params[:merchantEmail], payer_email: params[:payerEmail], invoice_url: create_invoice_response.invoiceURL, payer_view_url: create_invoice_response.payerViewURL, client_id: self.client_id)
      items_array.each do |item|
        InvoiceItem.create(resource: self, quantity: item[:quantity], unit_price: item[:unit_price], invoice_id: invoice.id, name: item[:name], invoice_item_type: invoice_item_type, description: item[:description])
      end
      invoice
    else
      nil
    end
  end

  def has_down_payment_items?
    InvoiceItem.where(resource: self, invoice_item_type: InvoiceItem.invoice_item_type.find_value(:down_payment).value).present?
  end

  private
    def automatic_invoices_enabled?
      self.send_automatic_invoices
    end

    def payment_amount_and_down_payment
      if payment_amount.present? && down_payment.present?
        if down_payment > payment_amount
          errors.add(:down_payment, "Should be less or equal than payment amount")
        end
        if down_payment.zero?
          errors.add(:down_payment, "Can't be zero")
        end
        if payment_amount.zero?
          errors.add(:payment_amount, "Can't be zero")
        end
        if down_payment != payment_amount
          if (!payment_duration.present? || payment_duration.zero?) && send_automatic_invoices
            errors.add(:payment_duration, "Can't be blank or zero if payment amount & down payment present and not equal")
          end
          if (!payment_frequency.present? || payment_frequency.zero?) && send_automatic_invoices
            errors.delete(:payment_frequency)
            errors.add(:payment_frequency, "Can't be blank if payment amount & down payment present and not equal")
          end
          if payment_duration.present? && payment_frequency.present? && payment_frequency > payment_duration
            errors.add(:payment_frequency, "Payment frequency can't be more than payment duration")
          end
        end
      else
        if payment_amount.present? && !down_payment.present?
          errors.add(:down_payment, "Can't be blank if payment amount present")
        end
        if !payment_amount.present? && down_payment.present?
          errors.add(:payment_amount, "Can't be blank if down payment present")
        end
      end
    end
end
