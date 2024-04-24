# frozen_string_literal: true

module UPS
  module Builders
    # The {RateBuilder} class builds UPS XML Rate Objects.
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
    end
  end
end
