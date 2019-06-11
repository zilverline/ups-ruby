module UPS
  module Models
    class PackageResult
      attr_reader :package_result

      def initialize(package_result)
        @package_result = package_result
      end

      def tracking_number
        package_result[:TrackingNumber]
      end

      def label_graphic_extension
        ".#{package_result[:LabelImage][:LabelImageFormat][:Code].downcase}"
      end

      def label_graphic_image
        Utils.base64_to_file(package_result[:LabelImage][:GraphicImage], label_graphic_extension)
      end

      def label_html_image
        Utils.base64_to_file(package_result[:LabelImage][:HTMLImage], label_graphic_extension)
      end
    end
  end
end
