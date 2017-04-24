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

    def cancel
      # TODO: confirm this change to invoice from sales receipt
      unless invoice = invoice_service.find_by_order_number
        raise RecordNotFound.new "Quickbooks Invoice not found for order #{order[:number]}"
      end

      credit_memo = credit_memo_service.create_from_receipt invoice
      text = "Created Quickbooks Credit Memo #{credit_memo.id} for canceled order #{invoice.doc_number}"
      [200, text]
    end
  end
end
