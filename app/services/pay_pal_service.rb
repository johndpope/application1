require 'paypal-sdk-invoice'
module PayPalService
  class << self
    def paypal_logger
      PayPal::SDK.logger
    end

    def init_api
      api = PayPal::SDK::Invoice::API.new
    end

    def create_invoice(params)
      ##params
      # {
      #   :invoice => {
      #     :merchantEmail => CONFIG['paypal']['merchant_email'],
      #     :payerEmail => "sender@yahoo.com",
      #     :itemList => {
      #       :item => [{
      #         :name => "item1",
      #         :quantity => 2.0,
      #         :unitPrice => 5.0 }] },
      #     :currencyCode => "USD",
      #     :paymentTerms => "DueOnReceipt" } }

      # Build request object
      create_invoice = init_api.build_create_invoice({:invoice => params})

      # Make API call & get response
      create_invoice_response = init_api.create_invoice(create_invoice)
      paypal_logger.info(create_invoice)
      paypal_logger.info(create_invoice_response)

      # Access Response
      if create_invoice_response.success?
        create_invoice_response.invoiceID
        create_invoice_response.invoiceNumber
        create_invoice_response.invoiceURL
        create_invoice_response.payerViewURL
        #wrong calculation here
        #create_invoice_response.totalAmount
      else
        create_invoice_response.error
      end
      create_invoice_response
    end

    def send_invoice(invoice_id)
      # Build request object
      send_invoice = init_api.build_send_invoice({:invoiceID => invoice_id })

      # Make API call & get response
      send_invoice_response = init_api.send_invoice(send_invoice)
      paypal_logger.info(send_invoice)
      paypal_logger.info(send_invoice_response)

      # Access Response
      if send_invoice_response.success?
        send_invoice_response.invoiceID
        send_invoice_response.invoiceURL
      else
        send_invoice_response.error
      end
      send_invoice_response
    end

    def create_and_send_invoice(params)
      ##params
      # {
      #   :invoice => {
      #     :merchantEmail => CONFIG['paypal']['merchant_email'],
      #     :payerEmail => "sender@yahoo.com",
      #     :itemList => {
      #       :item => [{
      #         :name => "item1",
      #         :quantity => 2.0,
      #         :unitPrice => 5.0 }] },
      #     :currencyCode => "USD",
      #     :paymentTerms => "DueOnReceipt" } }
      # Build request object
      create_and_send_invoice = init_api.build_create_and_send_invoice({:invoice => params})

      # Make API call & get response
      create_and_send_invoice_response = init_api.create_and_send_invoice(create_and_send_invoice)
      paypal_logger.info(create_and_send_invoice)
      paypal_logger.info(create_and_send_invoice_response)

      # Access Response
      if create_and_send_invoice_response.success?
        create_and_send_invoice_response.invoiceID
        create_and_send_invoice_response.invoiceNumber
        create_and_send_invoice_response.invoiceURL
        #wrong calculation here
        #create_and_send_invoice_response.totalAmount
      else
        create_and_send_invoice_response.error
      end
      create_and_send_invoice_response
    end

    def get_invoice_details(invoice_id)
      # Build request object
      get_invoice_details = init_api.build_get_invoice_details({:invoiceID => invoice_id })

      # Make API call & get response
      get_invoice_details_response = init_api.get_invoice_details(get_invoice_details)
      paypal_logger.info(get_invoice_details)
      paypal_logger.info(get_invoice_details_response)

      # Access Response
      if get_invoice_details_response.success?
        get_invoice_details_response.invoice
        #invoiceDetails.status, invoiceDetails.totalAmount
        get_invoice_details_response.invoiceDetails
        get_invoice_details_response.paymentDetails
        get_invoice_details_response.refundDetails
        get_invoice_details_response.invoiceURL
      else
        get_invoice_details_response.error
      end
      get_invoice_details_response
    end

    def cancel_invoice(invoice_id)
      # Build request object
      cancel_invoice = init_api.build_cancel_invoice({:invoiceID => invoice_id })

      # Make API call & get response
      cancel_invoice_response = init_api.cancel_invoice(cancel_invoice)
      paypal_logger.info(cancel_invoice)
      paypal_logger.info(cancel_invoice_response)

      # Access Response
      if cancel_invoice_response.success?
        cancel_invoice_response.invoiceID
        cancel_invoice_response.invoiceNumber
        cancel_invoice_response.invoiceURL
      else
        cancel_invoice_response.error
      end
      cancel_invoice_response
    end

    def update_invoice(invoice_id, details)
      ##details
      # :invoice => {
      #   :merchantEmail => CONFIG['paypal']['merchant_email'],
      #   :payerEmail => "sender@yahoo.com",
      #   :itemList => {
      #     :item => [{
      #       :name => "item1",
      #       :quantity => 2.0,
      #       :unitPrice => 5.0 }] },
      #   :currencyCode => "USD",
      #   :paymentTerms => "DueOnReceipt" }

      # Build request object
      update_invoice = init_api.build_update_invoice({:invoiceID => invoice_id, :invoice => details })

      # Make API call & get response
      update_invoice_response = init_api.update_invoice(update_invoice)
      paypal_logger.info(update_invoice)
      paypal_logger.info(update_invoice_response)

      # Access Response
      if update_invoice_response.success?
        update_invoice_response.invoiceID
        update_invoice_response.invoiceNumber
        update_invoice_response.invoiceURL
        update_invoice_response.totalAmount
      else
        update_invoice_response.error
      end
      update_invoice_response
    end

    def mark_invoice_as_paid(invoice_id, details = {})
      # Build request object
      mark_invoice_as_paid = init_api.build_mark_invoice_as_paid({
        :invoiceID => invoice_id,
        :payment => {
          :method => details[:method] || "PayPal",
          :note => details[:note] || "",
          :date => details[:date] || DateTime.now.to_s } })

      # Make API call & get response
      mark_invoice_as_paid_response = init_api.mark_invoice_as_paid(mark_invoice_as_paid)
      paypal_logger.info(mark_invoice_as_paid)
      paypal_logger.info(mark_invoice_as_paid_response)

      # Access Response
      if mark_invoice_as_paid_response.success?
        mark_invoice_as_paid_response.invoiceID
        mark_invoice_as_paid_response.invoiceNumber
        mark_invoice_as_paid_response.invoiceURL
      else
        mark_invoice_as_paid_response.error
      end
      mark_invoice_as_paid_response
    end

    def mark_invoice_as_unpaid(invoice_id)
      # Build request object
      mark_invoice_as_unpaid = init_api.build_mark_invoice_as_unpaid({
        :invoiceID => invoice_id })

      # Make API call & get response
      mark_invoice_as_unpaid_response = init_api.mark_invoice_as_unpaid(mark_invoice_as_unpaid)
      paypal_logger.info(mark_invoice_as_unpaid)
      paypal_logger.info(mark_invoice_as_unpaid_response)

      # Access Response
      if mark_invoice_as_unpaid_response.success?
        mark_invoice_as_unpaid_response.invoiceID
        mark_invoice_as_unpaid_response.invoiceNumber
        mark_invoice_as_unpaid_response.invoiceURL
      else
        mark_invoice_as_unpaid_response.error
      end
      mark_invoice_as_unpaid_response
    end

    def mark_invoice_as_refunded(invoice_id, details = {})
      # Build request object
      mark_invoice_as_refunded = init_api.build_mark_invoice_as_refunded({
        :invoiceID => invoice_id,
        :refundDetail => {
          :note => details[:note] || "",
          :date => details[:date] || DateTime.now.to_s} })

      # Make API call & get response
      mark_invoice_as_refunded_response = init_api.mark_invoice_as_refunded(mark_invoice_as_refunded)
      paypal_logger.info(mark_invoice_as_refunded)
      paypal_logger.info(mark_invoice_as_refunded_response)

      # Access Response
      if mark_invoice_as_refunded_response.success?
        mark_invoice_as_refunded_response.invoiceID
        mark_invoice_as_refunded_response.invoiceNumber
        mark_invoice_as_refunded_response.invoiceURL
      else
        mark_invoice_as_refunded_response.error
      end
      mark_invoice_as_refunded_response
    end

    def update_invoices_info
      paypal_logger.info("Update invoices info started at #{Time.now}")
      invoices = Invoice.where("invoice_id IS NOT NULL AND invoice_id <> '' AND status <> 'Paid' AND status <> 'Canceled'")
      invoices.each do |invoice|
        begin
          invoice.update_info
        rescue Exception => e
          paypal_logger.info(e.message)
          paypal_logger.info(e.backtrace)
        end
      end
      paypal_logger.info("Update invoices info finished at #{Time.now}")
    end

  end
end
