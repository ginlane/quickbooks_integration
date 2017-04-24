module QBIntegration
  module Service
    class Invoice < Base
      attr_reader :order, :payload
      attr_reader :payment_method_service, :line_service, :account_service, :customer_service

      def initialize(config, payload, options = { dependencies: true })
        super("Invoice", config)

        @order = payload[:order]

        if options[:dependencies]
          @payment_method_service = PaymentMethod.new config, payload
          @customer_service = Customer.new config, payload
          @account_service = Account.new config
          @line_service = Line.new config, payload
        end
      end

      def find(id)
        # quickbooks.fetch_by_id "#{id}"
        query = "SELECT * FROM Invoice WHERE DocNumber = '#{id}'"
        quickbooks.query(query).entries.first
      end

      def find_by_order_number
        query = "SELECT * FROM Invoice WHERE DocNumber = '#{order_number}'"
        quickbooks.query(query).entries.first
      end

      def create
         invoice = create_model
         build invoice

         begin
         quickbooks.create invoice
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
#         build invoice
#         if order[:shipments] && !order[:shipments].empty?
#           invoice.tracking_num = shipments_tracking_number.join(", ")
#           invoice.ship_method_ref = order[:shipments].last[:shipping_method]
#           invoice.ship_date = order[:shipments].last[:shipped_at]
#         end
#         quickbooks.update invoice
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
# 
           invoice.shipping_address = Address.build order["shipping_address"]
           invoice.billing_address = Address.build order["billing_address"]
# 
#           invoice.payment_method_id = payment_method_service.matching_payment.id
           customer_id = customer_service.find_or_create.id
           # invoice.customer_ref = Quickbooks::Model::EntityRef.new value: customer_id
           invoice.customer_ref = customer_id
# 
#           # Associated as both DepositAccountRef and IncomeAccountRef
#           #
#           # Quickbooks might return an weird error if the name here is already used
#           # by other, I think, quickbooks account
           income_account = account_service.find_by_name config.fetch("quickbooks_account_name")
# 
           # income_account = nil
           invoice.line_items = line_service.build_lines income_account
# 
#           # Default to Undeposit Funds account if no account is set
#           #
#           # Watch out for errors like:
#           #
#           #   A business validation error has occurred while processing your
#           #   request: Business Validation Error: You need to select a different
#           #   type of account for this transaction.
#           #
#           if config["quickbooks_deposit_to_account_name"].present?
#             deposit_account = account_service.find_by_name config.fetch("quickbooks_deposit_to_account_name")
#             invoice.deposit_to_account_id = deposit_account.id
#           end
        end

        def shipments_tracking_number
#           order[:shipments].map do |shipment|
#             shipment[:tracking]
#           end
        end
    end
  end
end
