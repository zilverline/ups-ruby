require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class ShipAcceptParser < ParserBase
      attr_accessor :label_root_path,
                    :form_root_path,
                    :label_graphic_image,
                    :label_graphic_extension,
                    :label_html_image,
                    :form_graphic_image,
                    :form_graphic_extension,
                    :tracking_number

      def value(value)
        initialize_document_root_paths

        parse_form_data(value)
        parse_label_data(value)
        parse_tracking_number(value)

        super
      end

      def initialize_document_root_paths
        self.label_root_path = [:ShipmentResults, :PackageResults, :LabelImage]
        self.form_root_path  = [:ShipmentResults, :Form, :Image]
      end

      def parse_form_data(value)
        graphic_extension_path = form_root_path + [:ImageFormat]

        parse_graphic_extension(graphic_extension_path, value, 'form')
        parse_graphic_image(form_root_path, value, 'form')
      end

      def parse_label_data(value)
        graphic_extension_path = label_root_path + [:LabelImageFormat]

        parse_graphic_extension(graphic_extension_path, value, 'label')
        parse_graphic_image(label_root_path, value, 'label')
        parse_html_image(label_root_path, value, 'label')
      end

      def parse_graphic_image(path, value, type)
        switch_path = path + [:GraphicImage].flatten
        return unless switch_active?(switch_path)

        self.send("#{type}_graphic_image=".to_sym, base64_to_file(value.as_s, type))
      end

      def parse_html_image(path, value, type)
        switch_path = path + [:HTMLImage].flatten
        return unless switch_active?(switch_path)

        self.send("#{type}_html_image=".to_sym, base64_to_file(value.as_s, type))
      end

      # Paths can differ a lot for different doc types and image format
      def parse_graphic_extension(path, value, type)
        switch_path = (path + [:Code]).flatten
        return unless switch_active?(switch_path)

        self.send("#{type}_graphic_extension=".to_sym, ".#{value.as_s.downcase}")
      end

      def parse_tracking_number(value)
        return unless switch_active?(:ShipmentIdentificationNumber)
        self.tracking_number = value.as_s
      end

      def base64_to_file(contents, type)
        file_config = ['ups', self.send("#{type}_graphic_extension".to_sym)]
        Tempfile.new(file_config, nil, encoding: 'ascii-8bit').tap do |file|
          begin
            file.write Base64.decode64(contents)
          ensure
            file.rewind
          end
        end
      end
    end
  end
end
