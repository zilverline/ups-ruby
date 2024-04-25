# frozen_string_literal: true

require 'uri'
require 'ox'
require 'json'

module UPS
  module Parsers
    class BaseParser
      attr_reader :response

      def initialize(response)
        @response = response
      end

      def success?
        status_code == '1'
      end

      def status_code
        root_response[:Response][:ResponseStatus][:Code]
      end

      def status_description
        root_response[:Response][:ResponseStatus][:Description]
      end

      def error_description
        build_error_description(error_response)
      end

      def parsed_response
        @parsed_response ||= JSON.parse(response, symbolize_names: true)
      end

      private

      def normalize_response_into_array(response_node)
        [response_node].flatten
      end

      def build_error_description(errors_node)
        errors_node.last[:Description]
      end

      def error_response
        root_response[:Response][:Alert]
      end
    end
  end
end
