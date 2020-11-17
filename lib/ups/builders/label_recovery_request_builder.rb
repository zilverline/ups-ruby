require 'ox'

module UPS
  module Builders
    # The {LabelRecoveryRequest} class builds UPS XML LabelRecoveryRequest Objects.
    #
    # @author Ed Phillips
    # @since 0.17.1
    class LabelRecoveryRequestBuilder < BuilderBase
      include Ox

      # Initializes a new {LabelRecoveryRequestBuilder} object
      #
      def initialize
        super 'LabelRecoveryRequest'

        root << multi_valued('Request', RequestAction: 'LabelRecovery')
      end

      # Adds a TrackingNumber to the XML document being built
      # according to user inputs
      #
      # @return [void]
      def add_tracking_number(number)
        root << element_with_value('TrackingNumber', number)
      end

      # Adds a ReferenceNumber to the XML document being built
      # according to user inputs
      # @param [String] value Customer supplied reference number.
      # @return [void]
      def add_reference_number(value)
        root << multi_valued('ReferenceNumber', Value: value)
      end

      # Adds a ShipperNumber to the XML document being built
      # according to user inputs
      # @param [String] shipper_number Shipper's six digit account number
      # @return [void]
      def add_shipper_number(shipper_number)
        root << element_with_value('ShipperNumber', shipper_number)
      end
    end
  end
end