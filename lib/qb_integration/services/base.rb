module QBIntegration
  module Service
    class Base
      def initialize(model_name, config)
        @model_name = model_name
        @config = config
        @quickbooks = create_service
      end

      def create(attributes = {})
        model = fill(create_model, attributes)
        @quickbooks.create model
      end

      def update(model, attributes = {})
        @quickbooks.update fill(model, attributes)
      end

      private
      def create_model
        "Quickbooks::Model::#{@model_name}".constantize.new
      end

      def create_service
        service = "Quickbooks::Service::#{@model_name}".constantize.new
        service.access_token = access_token
        service.company_id = @config.fetch('quickbooks.realm')
        service
      end

      def fill(item, attributes)
        attributes.each {|key, value| item.send("#{key}=", value)}
        item
      end

      def access_token
        @access_token ||= QBIntegration::Auth.new(
          token: @config.fetch("quickbooks.access_token"),
          secret: @config.fetch("quickbooks.access_secret")
        ).access_token
      end
    end
  end
end