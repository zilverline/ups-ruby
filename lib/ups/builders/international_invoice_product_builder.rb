require 'ox'

module UPS
  module Builders
    # The {InternationalProductInvoiceBuilder} class builds UPS XML International invoice Produt Objects.
    #
    # @author Calvin Hughes
    # @since 0.9.3
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

      def value
        element_with_value('Value', opts[:value])
      end

      def dimensions_unit
        unit_of_measurement(opts[:dimensions_unit])
      end

      def part_number
        element_with_value('PartNumber', opts[:part_number][0..9]) if opts[:part_number]
      end

      def commodity_code
        element_with_value('CommodityCode', opts[:commodity_code])
      end

      def origin_country_code
        element_with_value('OriginCountryCode', opts[:origin_country_code][0..2])
      end

      def product_unit
        Element.new('Unit').tap do |unit|
          unit << number
          unit << value
          unit << dimensions_unit
        end
      end

      # Returns an XML representation of the current object
      #
      # @return [Ox::Element] XML representation of the current object
      def to_xml
        Element.new(name).tap do |product|
          product << description
          product << commodity_code
          product << part_number
          product << origin_country_code
          product << product_unit
        end
      end
    end
  end
end
