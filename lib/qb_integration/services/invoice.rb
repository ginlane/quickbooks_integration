module QBIntegration
  module Service
    class Invoice < Base
      attr_reader :order, :payload
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service, :payment_service

      def initialize(config, payload, options = { dependencies: true })
        super("Invoice", config)

        @order = payload[:order]

        if options[:dependencies]
          @payment_method_service = PaymentMethod.new config, payload
          @customer_service = Customer.new config, payload
          @account_service = Account.new config
          @line_service = Line.new config, payload
          @payment_service = Payment.new config, payload
        end
      end

      def find_by_order_number
        query = "SELECT * FROM Invoice WHERE DocNumber = '#{order_number}'"
        quickbooks.query(query).entries.first
      end

      def create
        invoice = create_model
        build invoice

        begin
        qb_invoice = quickbooks.create invoice

        create_or_update_payments_for_invoice(qb_invoice.id)

        qb_invoice

        rescue Exception => e
          puts e.try :message
          puts e.try :code
          puts e.try :detail
          puts e.try :type
          puts e.try :request_xml
          puts e.try :request_json
          raise e
        end
      end

      def update(invoice)
        build invoice
        shipments = order[:shipments]
        if shipments && !shipments.empty?
          invoice.tracking_num = shipments_tracking_number.join(", ")
          invoice.ship_method_ref = shipments.last[:shipping_method]
          invoice.ship_date = shipments.last[:shipped_at]
        end
        qb_invoice = quickbooks.update invoice

        create_or_update_payments_for_invoice(qb_invoice.id)

        qb_invoice
      end

      def void(invoice)
        invoice = find_by_order_number
        quickbooks.void invoice
      end

      private
        def order_number
          order[:number] || order[:id]
        end

        def build(invoice)
          invoice.doc_number = order_number
          invoice.billing_email_address = order["email"]
          invoice.total = order['totals']['order']

          invoice.txn_date = order['placed_on']

          invoice.shipping_address = Address.build order["shipping_address"]
          invoice.billing_address = Address.build order["billing_address"]

          customer_id = customer_service.find_or_create.id
          invoice.customer_id = customer_id

          #
          # Associated as both DepositAccountRef and IncomeAccountRef
          #
          # Quickbooks might return a weird error if the name here is already used
          # by other, I think, quickbooks account
          income_account = account_service.find_by_name config.fetch("quickbooks_account_name")

          invoice.line_items = line_service.build_lines income_account
        end

        def shipments_tracking_number
           order[:shipments].map do |shipment|
             shipment[:tracking]
           end
        end

        def create_or_update_payments_for_invoice(invoice_id)
          payment_service.create_or_update_for_invoice(invoice_id)
        end
    end
  end
end
