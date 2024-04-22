require 'uri'

module UPS
  module Parsers
    class TrackParser < BaseParser
      def initialize(response)
        # Unescape double/triple quoted first line: "<?xml version=\\\"1.0\\\"?>\\n<TrackResponse>\n"
        super(response.gsub(/\\"/, '"').gsub(/\\n/, "\n"))
      end

      def to_h
        {
          status_date: status_date,
          status_type_description: status_type_description,
          status_type_code: status_type_code
        }
      end

      def status_date
        Date.parse(latest_activity[:date])
      end

      def status_type_description
        status_type[:description]
      end

      def status_type_code
        status_type[:code]
      end

      private

      def status_type
        latest_activity[:status]
      end

      def latest_activity
        activities.sort_by {|a| [a[:gmtDate], a[:gmtTime]] }.last
      end

      def activities
        normalize_response_into_array(root_response[:shipment][0][:package][0][:activity])
      end

      def root_response
        parsed_response[:trackResponse]
      end
    end
  end
end
