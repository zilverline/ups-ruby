require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class ShipAcceptParser < BaseParser

      def tracking_number
        shipment_results[:ShipmentIdentificationNumber]
      end

      def label_graphic_extension
        ".#{package_results[:LabelImage][:LabelImageFormat][:Code].downcase}"
      end

      def label_graphic_image
        base64_to_file(package_results[:LabelImage][:GraphicImage], label_graphic_extension)
      end

      def label_html_image
        base64_to_file(package_results[:LabelImage][:HTMLImage], label_graphic_extension)
      end

      alias_method :graphic_extension, :label_graphic_extension
      alias_method :graphic_image, :label_graphic_image
      alias_method :html_image, :label_html_image

      def form_graphic_extension
        ".#{shipment_results[:Form][:Image][:ImageFormat][:Code].downcase}"
      end

      def form_graphic_image
        base64_to_file(shipment_results[:Form][:Image][:GraphicImage], label_graphic_extension)
      end

      private

      def base64_to_file(contents, extension)
        file_config = ['ups', extension]
        Tempfile.new(file_config, nil, encoding: 'ascii-8bit').tap do |file|
          begin
            file.write Base64.decode64(contents)
          ensure
            file.rewind
          end
        end
      end

      def package_results
        shipment_results[:PackageResults]
      end

      def shipment_results
        root_response[:ShipmentResults]
      end

      def root_response
        parsed_response[:ShipmentAcceptResponse]
      end
    end
  end
end
