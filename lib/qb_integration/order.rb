module QBIntegration
  class Order < Base
    attr_accessor :order

    def initialize(message = {}, config)
      super(message, config)
      @order = payload[:order]
    end

    def find(id)
      invoice_service.find id
    end

    def create
      if invoice = invoice_service.find_by_order_number
        raise AlreadyPersistedOrderException.new(
          "Order #{order[:id]} already has an Invoice with id: #{invoice.id}"
        )
      end

      invoice = invoice_service.create
      text = "Created Quickbooks Invoice #{invoice.id} for order #{invoice.doc_number}"
      [200, text]
    end

    def update
      invoice = invoice_service.find_by_order_number

      if !invoice.present? && config[:quickbooks_create_or_update].to_s == "1"
        invoice = invoice_service.create
        [200, "Created Quickbooks Invoice #{invoice.doc_number}"]
      elsif !invoice.present?
        raise RecordNotFound.new "Quickbooks Invoice not found for order #{order[:number]}"
      else
        invoice = invoice_service.update invoice
        [200, "Updated Quickbooks Invoice #{invoice.doc_number}"]
      end
    end

    # Voids an existing invoice as well as the payment associated to it, if any exist
    def cancel
      unless invoice = invoice_service.find_by_order_number
        raise RecordNotFound.new "Quickbooks Invoice not found for order #{order[:number]}"
      end

      if invoice_service.void invoice
        response = 200
        text = "Voided Quickbooks Invoice #{invoice.doc_number}"
      else
        response = 500
        text = "Failed to void Quickbooks Invoice #{invoice.doc_number}"
      end

      [response, text]
    end
  end
end
