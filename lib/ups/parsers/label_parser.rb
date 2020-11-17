require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class LabelParser < BaseParser
      def tracking_number
        labels[0].tracking_number
      end

      def label_graphic_extension
        labels[0].label_graphic_extension
      end

      def label_graphic_image
        labels[0].label_graphic_image
      end

      def label_html_image
        labels[0].label_html_image
      end

      alias_method :graphic_extension, :label_graphic_extension
      alias_method :graphic_image, :label_graphic_image
      alias_method :html_image, :label_html_image

      def labels
        return label_results.map { |label_result| UPS::Models::PackageResult.new(label_result) } if label_results.is_a?(Array)

        [UPS::Models::PackageResult.new(label_results)]
      end

      private

      def label_results
        root_response[:LabelResults]
      end

      def root_response
        parsed_response[:LabelRecoveryResponse]
      end
    end
  end
end
