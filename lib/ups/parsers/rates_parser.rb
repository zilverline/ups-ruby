module UPS
  module Parsers
    class RatesParser < BaseParser

      def rated_shipments
        rates.map do |rated_shipment|
          RateParser.new(rated_shipment).to_h
        end
      end

      private

      def rates
        root_response[:RatedShipment]
      end

      def root_response
        parsed_response[:RatingServiceSelectionResponse]
      end
    end
  end
end
