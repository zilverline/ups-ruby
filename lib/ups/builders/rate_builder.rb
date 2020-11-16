require 'ox'

module UPS
  module Builders
    # The {RateBuilder} class builds UPS XML Rate Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    class RateBuilder < BuilderBase
      include Ox

      # Initializes a new {RateBuilder} object
      #
      def initialize
        super 'RatingServiceSelectionRequest'

        add_request('Rate', 'Shop')
      end


      # Adds ReturnService to XML document being built
      #
      # @param [String] service_code The code for Return Service type
      #
      # @return [void]
      def add_return_service(service_code, service_description = '')
          shipment_service_options << code_description('ReturnService',
                                            service_code,
                                            service_description)
        end
      end
    end
  end
end
