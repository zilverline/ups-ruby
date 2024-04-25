# frozen_string_literal: true

module UPS
  module Parsers
    class RatesParser < BaseParser
      def rated_shipments
        rates.map do |rated_shipment|
          RateParser.new(rated_shipment).as_json
        end
      end

      private

      def rates
        normalize_response_into_array(root_response[:RatedShipment])
      end

      def root_response
        parsed_response[:RateResponse]
      end
    end
  end
end
