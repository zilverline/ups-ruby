# frozen_string_literal: true

module UPS
  module Builders
    # The {ShipBuilder} class builds UPS JSON Ship Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    class ShipBuilder < BuilderBase
      # Initializes a new {ShipBuilder} object
      #
      def initialize
        super 'ShipmentRequest'

        add_request 'validate'
      end

      # Adds a LabelSpecification section to the JSON body being built
      #
      # @return [void]
      def add_label_specification(format, size)
        root.merge!(element_with_value('LabelSpecification', {}))
        root['LabelSpecification'].merge!(label_image_format(format),
                                          label_stock_size(size))

        if gif?(format)
          root['LabelSpecification'].merge!(http_user_agent)
        end
      end

      # Adds a InternationalForms section to the JSON body being built
      #
      # @return [void]
      def add_international_invoice(opts = {})
        shipment_service_options.merge!(InternationalInvoiceBuilder.new('InternationalForms', opts).as_json)
      end

      # Adds a Service section to the JSON body being built
      #
      # @param [String] service_code The Service code for the choosen Shipping
      #   method
      # @param [optional, String] service_description A description for the
      #   choosen Shipping Method
      # @return [void]
      def add_service(service_code, service_description = '')
        shipment_root.merge!(code_description('Service',
                                              service_code,
                                              service_description))
      end

      # Adds an InvoiceLineTotal section to the JSON body being built
      #
      # @param [String] value Amount for the entire shipment
      # @param [String] currency_code Currency code for the amount
      def add_invoice_line_total(value, currency_code)
        shipment_root.merge!(invoice_line_total(value, currency_code))
      end

      # Adds Description to JSON body being built
      #
      # @param [String] description The description for goods being sent
      # @return [void]
      def add_description(description)
        shipment_root.merge!(element_with_value('Description', description))
      end

      # Adds ReferenceNumber to the JSON body being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :code Code
      # @option opts [String] :value Value
      # @return [void]
      def add_reference_number(opts = {})
        shipment_root.merge!(reference_number(opts[:code], opts[:value]))
      end

      private

      def gif?(string)
        string.downcase == 'gif'
      end

      def http_user_agent
        element_with_value('HTTPUserAgent', version_string)
      end

      def version_string
        "RubyUPS/#{UPS::Version::STRING}"
      end

      def label_image_format(format)
        code_description 'LabelImageFormat', format.to_s, format.to_s
      end

      def label_stock_size(size)
        multi_valued('LabelStockSize',
                     'Height' => size[:height].to_s,
                     'Width' => size[:width].to_s)
      end

      def reference_number(code, value)
        multi_valued('ReferenceNumber',
                     'Code' => code.to_s,
                     'Value' => value.to_s)
      end

      def invoice_line_total(value, currency_code)
        multi_valued('InvoiceLineTotal',
                     'CurrencyCode' => currency_code.to_s,
                     'MonetaryValue' => value.to_s)
      end
    end
  end
end
