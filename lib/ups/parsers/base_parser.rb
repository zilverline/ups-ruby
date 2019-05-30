require 'uri'
require 'ox'

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
        root_response[:Response][:ResponseStatusCode]
      end

      def status_description
        root_response[:Response][:ResponseStatusDescription]
      end

      def error_description
        root_response[:Response][:Error][:ErrorDescription]
      end

      def parsed_response
        @parsed_response ||= Ox.load(response, mode: :hash)
      end
    end
  end
end
