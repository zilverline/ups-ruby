# frozen_string_literal: true

module UPS
  module Builders
    # The {RateBuilder} class builds UPS Rate Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    class RateBuilder < BuilderBase
      # Initializes a new {RateBuilder} object
      #
      def initialize
        super 'RateRequest'

        add_request 'Shop'
      end

      # Adds ReturnService to JSON body being built
      #
      # @param [String] service_code The code for Return Service type
      # @return [void]
      def add_return_service(service_code, service_description = '')
        shipment_service_options.merge!(code_description('ReturnService',
                                                         service_code,
                                                         service_description))
      end
    end
  end
end
