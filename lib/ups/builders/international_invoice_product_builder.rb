require 'ox'

module UPS
  module Builders
    # The {InternationalProductInvoiceBuilder} class builds UPS XML International invoice Produt Objects.
    #
    # @attr [String] name The Containing XML Element Name
    # @attr [Hash] opts The international invoice product parts
    class InternationalInvoiceProductBuilder < BuilderBase
      include Ox

      attr_accessor :name, :opts

      def initialize(name, opts = {})
        self.name = name
        self.opts = opts
      end

      def description
        element_with_value('Description', opts[:description])
      end

      def number
        element_with_value('Number', opts[:number])
      end

      def dimensions_unit
        unit_of_measurement(opts[:dimensions_unit])
      end

      def part_number
        element_with_value('PartNumber', opts[:part_number]) if opts[:part_number]
      end

      def commodity_code
        element_with_value('CommodityCode', opts[:commodity_code])
      end

      def origin_country_code
        element_with_value('OriginCountryCode', opts[:origin_country_code])
      end

      def product_unit
        Element.new('Unit').tap do |unit|
          unit << description
          unit << number
          unit << dimensions_unit
          unit << part_number
          unit << commodity_code
          unit << origin_country_code
        end
      end

      # Returns an XML representation of the current object
      #
      # @return [Ox::Element] XML representation of the current object
      def to_xml
        Element.new(name).tap do |product|
          product << description
          product << product_unit
        end
      end
    end
  end
end
