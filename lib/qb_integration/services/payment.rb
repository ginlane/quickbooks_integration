module QBIntegration
  module Service
    class Payment < Base
      attr_reader :order
      attr_reader :customer_service

      def initialize(config, payload)
        super("Payment", config)

        @order = payload[:order] || {}
        @payments = order[:payments] || []

        @customer_service = Customer.new config, payload
      end

      def create_or_update_for_invoice(invoice_id)
        @payments.map do |payment|
          qb_payment = find_or_new payment[:number]
          qb_payment = build_for_invoice qb_payment, payment, invoice_id
          if qb_payment.id.nil?
            quickbooks.create qb_payment
          else
            quickbooks.update qb_payment
          end
        end
      end

      def find_or_new(payment_number)
        fetch_by_payment_ref_number(payment_number) || create_model
      end

      def fetch_by_payment_ref_number(num)
        util = Quickbooks::Util::QueryBuilder.new
        clause = util.clause("PaymentRefNum", "=", num)

        query = "SELECT * FROM Payment WHERE #{clause}"
        quickbooks.query(query).entries.first
      end

      def build_for_invoice(qb_payment, payment, invoice_id)
        filled_payment = qb_payment
        filled_payment.total = payment[:amount]

        filled_payment.customer_id = customer_service.find_or_create.id

        txn_line = Quickbooks::Model::Line.new
        txn_line.invoice_id = invoice_id
        txn_line.amount = payment[:amount]

        filled_payment.line_items = [txn_line]

        filled_payment.payment_ref_number = payment[:number]

        filled_payment
      end
    end
  end
end
