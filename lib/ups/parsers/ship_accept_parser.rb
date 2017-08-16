require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class ShipAcceptParser < ParserBase
      attr_accessor :label_graphic_image,
                    :label_graphic_extension,
                    :label_html_image,
                    :form_graphic_image,
                    :form_graphic_extension,
                    :form_html_image,
                    :tracking_number

      def value(value)
        parse_form_data(value)
        parse_label_data(value)
        parse_tracking_number(value)

        super
      end

      def parse_form_data(value)
        root_path = [:PackageResults, :Form, :Image]
        graphic_extension_path = root_path + [:ImageFormat, :Code]
        document_type = 'form'

        parse_graphic_image(root_path, value, document_type)
        parse_graphic_extension(graphic_extension_path, value, document_type)
      end

      def parse_label_data(value)
        root_path = [:PackageResults, :LabelImage]
        graphic_extension_path = root_path + [:LabelImageFormat, :Code]
        document_type = 'label'

        parse_graphic_image(root_path, value, document_type)
        parse_html_image(root_path, value, document_type)
        parse_graphic_extension(graphic_extension_path, value, document_type)
      end

      def parse_graphic_image(path, value, type)
        #switch_path = path + [:GraphicImage].flatten
        return unless switch_active?(:GraphicImage)

        self.send("#{type}_graphic_image=".to_sym, base64_to_file(value.as_s, type))
      end

      def parse_html_image(path, value, type)
        #switch_path = path + [:HTMLImage].flatten
        return unless switch_active?(:HTMLImage)

        self.send("#{type}_html_image=".to_sym, base64_to_file(value.as_s, type))
      end

      # Paths can differ a lot for different doc types and image format
      def parse_graphic_extension(path, value, type)
        return unless switch_active?(:LabelImageFormat, :Code)
        self.send("#{type}_graphic_extension=".to_sym, ".#{value.as_s.downcase}")
      end

      def parse_tracking_number(value)
        return unless switch_active?(:ShipmentIdentificationNumber)
        self.tracking_number = value.as_s
      end

      def base64_to_file(content, type)
        file_config = ['ups', self.send("#{type}_graphic_extension".to_sym)]
        Tempfile.new(file_config, nil, encoding: 'ascii-8bit').tap do |file|
          begin
            file.write Base64.decode64(content)
          ensure
            file.rewind
          end
        end
      end
    end
  end
end
