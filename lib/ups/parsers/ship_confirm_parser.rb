module UPS
  module Parsers
    class ShipConfirmParser < BaseParser

      def identification_number
        root_response[:ShipmentIdentificationNumber]
      end

      def shipment_digest
        root_response[:ShipmentDigest]
      end

      private

      def root_response
        parsed_response[:ShipmentConfirmResponse]
      end
    end
  end
end
