require 'uri'
require 'ox'

module UPS
  module Parsers
    class RateParser
      attr_reader :rate

      def initialize(rate)
        @rate = rate
      end

      def to_h
        {
          service_code: rate_service_code,
          service_name: rate_service_name,
          warnings:     rate_warnings,
          total:        rate_total
        }
      end

      def rate_service_name
        UPS::SERVICES[rate_service_code]
      end

      def rate_service_code
        rate_service[:Code]
      end

      private

      def rate_total
        return total_charges[:MonetaryValue] unless negotiated_rates

        negotiated_rates[:NetSummaryCharges][:GrandTotal][:MonetaryValue]
      end

      def rate_warnings
        rated_shipment_warning.is_a?(Array) ? rated_shipment_warning : [rated_shipment_warning]
      end

      def rate_service
        rate[:Service]
      end

      def rated_shipment_warning
        rate[:RatedShipmentWarning]
      end

      def total_charges
        rate[:TotalCharges]
      end

      def negotiated_rates
        rate[:NegotiatedRates]
      end
    end
  end
end
