require 'ox'
require 'excon'
require 'base64'

module UPS
  module Builders
    # The {BuilderBase} class builds UPS XML Address Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @abstract
    # @attr [Ox::Document] document The XML Document being built
    # @attr [Ox::Element] root The XML Root
    # @attr [Ox::Element] shipment_root The XML Shipment Element
    # @attr [Ox::Element] access_request The XML AccessRequest Element
    # @attr [String] license_number The UPS API Key
    # @attr [String] user_id The UPS Username
    # @attr [String] password The UPS Password
    class BuilderBase
      include Ox
      include Exceptions

      attr_accessor :document,
                    :root,
                    :shipment_root,
                    :access_request,
                    :license_number,
                    :user_id,
                    :password

      # Initializes a new {BuilderBase} object
      #
      # @param [String] root_name The Name of the XML Root
      # @return [void]
      def initialize(root_name)
        initialize_xml_roots root_name

        document << access_request
        document << root

        @token_data = nil

        yield self if block_given?
      end

      # Creates a new access token
      #
      # @param [String] base_url The base URL to use for the token creation request
      # @param [String] account_number Account number to use for the request
      # @param [String] client_id Client ID to use
      # @param [String] client_secret Client secret to use
      # @return [void]
      def create_token(base_url, account_number, client_id, client_secret)
        full_url = base_url + '/security/v1/oauth/token'
        auth = 'Basic ' + Base64.strict_encode64("#{client_id}:#{client_secret}")

        params = {
          'grant_type' => 'client_credentials'
        }

        begin
          response = Excon.post(
            full_url,
            body: URI.encode_www_form(params),
            headers: {
              'Content-Type' => 'application/x-www-form-urlencoded',
              'x-merchant-id' => account_number,
              'Authorization' => auth
            }
          )

          if response.status == 200
            @token_data = JSON.parse(response.body)
          else
            raise "Unexpected response status: #{response.status}"
          end

        rescue Excon::Errors::Timeout
          fail AuthorizationError, 'Token creation request timed out'
        rescue Excon::Errors::SocketError
          fail AuthorizationError, 'Token creation request failed due to socket error'
        rescue => e
          fail AuthorizationError, "Token creation request failed: #{e.message}"
        end
      end

      # Refreshes the access token once it has expired
      #
      # @param [String] base_url The base URL to use for the token refresh request
      # @param [String] client_id Client ID to use
      # @param [String] client_secret Client secret to use
      # @param [String] refresh_token Refresh token to use for the request
      # @return [void]
      def refresh_token(base_url, client_id, client_secret, refresh_token)
        full_url = base_url + '/security/v1/oauth/refresh'
        auth = 'Basic ' + Base64.strict_encode64("#{client_id}:#{client_secret}")

        params = {
          'grant_type' => 'refresh_token',
          'refresh_token' => refresh_token
        }

        begin
          response = Excon.post(
            full_url,
            body: URI.encode_www_form(params),
            headers: {
              'Content-Type' => 'application/x-www-form-urlencoded',
              'Authorization' => auth
            }
          )

          if response.status == 200
            @token_data = JSON.parse(response.body)
          else
            raise "Unexpected response status: #{response.status}"
          end

        rescue Excon::Errors::Timeout
          fail AuthorizationError, 'Token refresh request timed out'
        rescue Excon::Errors::SocketError
          fail AuthorizationError, 'Token refresh request failed due to socket error'
        rescue => e
          fail AuthorizationError, "Token refresh request failed: #{e.message}"
        end
      end

      # Retrieves the access token, or refreshes it if it has expired
      #
      # @param [String] base_url The base URL to use for if the token needs to be refreshed
      # @param [String] client_id Client ID to use
      # @param [String] client_secret Client secret to use
      # @return [String] The access token
      def get_access_token(base_url, client_id, client_secret)
        if @token_data.nil?
          fail AuthorizationError, 'No token data found, please call create_token first'
        end

        issued_at = @token_data['issued_at'].to_i
        expires_in = @token_data['expires_in'].to_i
        current_time = Time.now.to_i

        # Token is expired, refresh it
        if issued_at + expires_in <= current_time
          refresh_token(base_url, client_id, client_secret, @token_data['refresh_token'])
        end

        @token_data['access_token']
      end

      # Initializes a new {BuilderBase} object
      #
      # @param [String] license_number The UPS API Key
      # @param [String] user_id The UPS Username
      # @param [String] password The UPS Password
      # @return [void]
      def add_access_request(license_number, user_id, password)
        self.license_number = license_number
        self.user_id = user_id
        self.password = password

        access_request << element_with_value('AccessLicenseNumber',
                                             license_number)
        access_request << element_with_value('UserId', user_id)
        access_request << element_with_value('Password', password)
      end

      # Adds an InsuranceCharges section to the XML document being built
      #
      # @param [String] value The MonetaryValue of the InsuranceCharge
      # @return [void]
      def add_insurance_charge(value)
        shipment_root << insurance_charge(value)
      end

      # Adds a Request section to the XML document being built
      #
      # @param [String] action The UPS API Action requested
      # @param [String] option The UPS API Option
      # @return [void]
      def add_request(action, option)
        root << Element.new('Request').tap do |request|
          request << element_with_value('RequestAction', action)
          request << element_with_value('RequestOption', option)
        end
      end

      # Adds a Shipper section to the XML document being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @option opts [String] :shipper_number UPS Account Number
      # @return [void]
      def add_shipper(opts = {})
        shipment_root << ShipperBuilder.new(opts).to_xml
      end

      # Adds a ShipTo section to the XML document being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @return [void]
      def add_ship_to(opts = {})
        shipment_root << OrganisationBuilder.new('ShipTo', opts).to_xml
      end

      # Adds a SoldTo section to the XML document being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @return [void]
      def add_sold_to(opts = {})
        shipment_root << OrganisationBuilder.new('SoldTo', opts).to_xml
      end

      # Adds a ShipFrom section to the XML document being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @option opts [String] :company_name Company Name
      # @option opts [String] :phone_number Phone Number
      # @option opts [String] :address_line_1 Address Line 1
      # @option opts [String] :city City
      # @option opts [String] :state State
      # @option opts [String] :postal_code Zip or Postal Code
      # @option opts [String] :country Country
      # @option opts [String] :shipper_number UPS Account Number
      # @return [void]
      def add_ship_from(opts = {})
        shipment_root << OrganisationBuilder.new('ShipFrom', opts).to_xml
      end

      # Adds a Package section to the XML document being built
      #
      # @param [Hash] opts A Hash of data to build the requested section
      # @return [void]
      def add_package(opts = {})
        shipment_root << Element.new('Package').tap do |org|
          org << packaging_type(opts[:packaging_type] || customer_supplied_packaging)
          org << element_with_value('Description', 'Rate')
          org << package_weight(opts[:weight], opts[:unit])
          org << package_dimensions(opts[:dimensions]) if opts[:dimensions]
        end
      end

      def customer_supplied_packaging
        {code: '02', description: 'Customer Supplied Package'}
      end

      # Adds a PaymentInformation section to the XML document being built
      #
      # @param [String] ship_number The UPS Shipper Number
      # @return [void]
      def add_payment_information(ship_number)
        shipment_root << Element.new('PaymentInformation').tap do |payment|
          payment << Element.new('Prepaid').tap do |prepaid|
            prepaid << Element.new('BillShipper').tap do |bill_shipper|
              bill_shipper << element_with_value('AccountNumber', ship_number)
            end
          end
        end
      end

      # Adds a RateInformation/NegotiatedRatesIndicator section to the XML
      # document being built
      #
      # @return [void]
      def add_rate_information
        shipment_root << Element.new('RateInformation').tap do |rate_info|
          rate_info << element_with_value('NegotiatedRatesIndicator', '1')
        end
      end

      # Adds a Delivery Confirmation DCIS Type to the shipment service options
      #
      # @param [String] dcis_type DCIS type
      # @return [void]
      def add_shipment_delivery_confirmation(dcis_type)
        shipment_service_options <<
          Element.new('DeliveryConfirmation').tap do |delivery_confirmation|
            delivery_confirmation << element_with_value('DCISType', dcis_type)
          end
      end

      # Adds Direct Delivery Only indicator to the shipment service options
      #
      # @return [void]
      def add_shipment_direct_delivery_only
        shipment_service_options << Element.new('DirectDeliveryOnlyIndicator')
      end

      # Returns a String representation of the XML document being built
      #
      # @return [String]
      def to_xml
        Ox.to_xml document
      end

      private

      def initialize_xml_roots(root_name)
        self.document = Document.new
        self.root = Element.new(root_name)
        self.shipment_root = Element.new('Shipment')
        self.access_request = Element.new('AccessRequest')
        root << shipment_root
      end

      def shipment_service_options
        @shipment_service_options ||= begin
          Element.new('ShipmentServiceOptions').tap do |element|
            shipment_root << element
          end
        end
      end

      def packaging_type(packaging_options_hash)
        code_description 'PackagingType', packaging_options_hash[:code], packaging_options_hash[:description]
      end

      def package_weight(weight, unit)
        Element.new('PackageWeight').tap do |org|
          org << unit_of_measurement(unit)
          org << element_with_value('Weight', weight)
        end
      end

      def package_dimensions(dimensions)
        Element.new('Dimensions').tap do |org|
          org << unit_of_measurement(dimensions[:unit])
          org << element_with_value('Length', dimensions[:length].to_s[0..8])
          org << element_with_value('Width', dimensions[:width].to_s[0..8])
          org << element_with_value('Height', dimensions[:height].to_s[0..8])
        end
      end

      def unit_of_measurement(unit)
        Element.new('UnitOfMeasurement').tap do |org|
          org << element_with_value('Code', unit.to_s)
        end
      end

      def element_with_value(name, value)
        fail InvalidAttributeError, name unless value.respond_to?(:to_str)
        Element.new(name).tap do |request_action|
          request_action << value.to_str
        end
      end

      def code_description(name, code, description)
        multi_valued(name, Code: code, Description: description)
      end

      def insurance_charge(value)
        multi_valued('InsuranceCharges', MonetaryValue: value)
      end

      def multi_valued(name, params)
        Element.new(name).tap do |e|
          params.each { |key, value| e << element_with_value(key, value) }
        end
      end
    end
  end
end
