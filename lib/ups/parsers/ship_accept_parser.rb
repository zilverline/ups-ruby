require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class ShipAcceptParser < ParserBase
      attr_accessor :label_root_path,
                    :form_root_path,
                    :graphic_image,
                    :graphic_extension,
                    :html_image,
                    :label_graphic_image,
                    :label_graphic_extension,
                    :label_html_image,
                    :form_graphic_image,
                    :form_graphic_extension,
                    :tracking_number

      def value(value)
        initialize_document_root_paths

        parse_document_data(value, 'label')
        parse_document_data(value, 'form')
        parse_tracking_number(value)

        super
      end

      def initialize_document_root_paths
        self.label_root_path = [:ShipmentResults, :PackageResults, :LabelImage]
        self.form_root_path  = [:ShipmentResults, :Form, :Image]
      end

      def parse_document_data(value, type)
        root_path = self.send("#{type}_root_path")

        parse_graphic_extension(root_path, value, type)
        parse_graphic_image(root_path, value, type)
        parse_html_image(root_path, value, type)
      end

      def parse_graphic_image(root_path, value, type)
        switch_path = build_switch_path(root_path, :GraphicImage)
        return unless switch_active?(switch_path)

        self.send("#{type}_graphic_image=".to_sym, base64_to_file(value.as_s, type))
        self.send("graphic_image=".to_sym, base64_to_file(value.as_s, type)) if type == 'label'
      end

      def parse_html_image(root_path, value, type)
        switch_path = build_switch_path(root_path, :HTMLImage)
        return unless switch_active?(switch_path)

        self.send("#{type}_html_image=".to_sym, base64_to_file(value.as_s, type))
        self.send("html_image=".to_sym, base64_to_file(value.as_s, type)) if type == 'label'
      end

      def parse_graphic_extension(root_path, value, type)
        graphic_extension_subpath = (type == 'label' ? :LabelImageFormat : :ImageFormat)

        switch_path = build_switch_path(root_path, graphic_extension_subpath, :Code)
        return unless switch_active?(switch_path)

        self.send("#{type}_graphic_extension=".to_sym, ".#{value.as_s.downcase}")
        self.send("graphic_extension=".to_sym, ".#{value.as_s.downcase}") if type == 'label'
      end

      def parse_tracking_number(value)
        return unless switch_active?(:ShipmentIdentificationNumber)
        self.tracking_number = value.as_s
      end

      def build_switch_path(*paths)
        paths.flatten
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
