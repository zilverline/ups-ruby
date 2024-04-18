require 'uri'
require 'excon'
require 'digest/md5'
require 'ox'
require 'base64'

module UPS
  # The {Connection} class acts as the main entry point to performing rate and
  # ship operations against the UPS API.
  #
  # @author Paul Trippett
  # @abstract
  # @since 0.1.0
  # @attr [String] url The base url to use either TEST_URL or LIVE_URL
  class Connection
    attr_accessor :url,
                  :account_number,
                  :client_id,
                  :client_secret

    TEST_URL = 'https://wwwcie.ups.com'
    LIVE_URL = 'https://onlinetools.ups.com'

    RATE_PATH = '/ups.app/xml/Rate'
    SHIP_CONFIRM_PATH = '/ups.app/xml/ShipConfirm'
    SHIP_ACCEPT_PATH = '/ups.app/xml/ShipAccept'
    ADDRESS_PATH = '/ups.app/xml/XAV'
    TRACK_PATH = '/ups.app/xml/Track'

    DEFAULT_PARAMS = {
      test_mode: false
    }

    # Initializes a new {Connection} object
    #
    # @param [Hash] params The initialization options
    # @option params [Boolean] :test_mode If TEST_URL should be used for
    #   requests to the UPS URL
    def initialize(params = {})
      params = DEFAULT_PARAMS.merge(params)
      self.url = (params[:test_mode]) ? TEST_URL : LIVE_URL

      @token_data = nil
    end

    # Makes a request to fetch Rates for a shipment.
    #
    # A pre-configured {Builders::RateBuilder} object can be passed as the first
    # option or a block yielded to configure a new {Builders::RateBuilder}
    # object.
    #
    # @param [Builders::RateBuilder] rate_builder A pre-configured
    #   {Builders::RateBuilder} object to use
    # @yield [rate_builder] A RateBuilder object for configuring
    #   the shipment information sent
    def rates(rate_builder = nil)
      if rate_builder.nil? && block_given?
        rate_builder = UPS::Builders::RateBuilder.new
        yield rate_builder
      end

      response = get_response(RATE_PATH, rate_builder.to_xml)
      UPS::Parsers::RatesParser.new(response.body)
    end

    # Makes a request to ship a package
    #
    # A pre-configured {Builders::ShipConfirmBuilder} object can be passed as
    # the first option or a block yielded to configure a new
    # {Builders::ShipConfirmBuilder} object.
    #
    # @param [Builders::ShipConfirmBuilder] confirm_builder A pre-configured
    #   {Builders::ShipConfirmBuilder} object to use
    # @yield [ship_confirm_builder] A ShipConfirmBuilder object for configuring
    #   the shipment information sent
    def ship(confirm_builder = nil)
      if confirm_builder.nil? && block_given?
        confirm_builder = Builders::ShipConfirmBuilder.new
        yield confirm_builder
      end

      confirm_response = make_confirm_request(confirm_builder)
      return confirm_response unless confirm_response.success?

      accept_builder = build_accept_request_from_confirm(confirm_builder, confirm_response)
      make_accept_request(accept_builder)
    end

    # Makes a request to Track the status for a shipment.
    #
    # A pre-configured {Builders::TrackBuilder} object can be passed as the first
    # option or a block yielded to configure a new {Builders::TrackBuilder}
    # object.
    #
    # @param [Builders::TrackBuilder] track_builder A pre-configured
    #   {Builders::TrackBuilder} object to use
    # @yield [track_builder] A TrackBuilder object for configuring
    #   the shipment information sent
    def track(track_builder = nil)
      if track_builder.nil? && block_given?
        track_builder = UPS::Builders::TrackBuilder.new
        yield track_builder
      end

      response = get_response(TRACK_PATH, track_builder.to_xml)

      UPS::Parsers::TrackParser.new(response.body)
    end

    private

    def build_url(path)
      "#{url}#{path}"
    end

    def get_response(path, body)
      access_token = get_access_token()

      Excon.post(
        build_url(path),
        body: body,
        headers: {
          'Authorization' => "Bearer #{access_token}"
        }
      )
    end

    def make_confirm_request(confirm_builder)
      make_ship_request(confirm_builder, SHIP_CONFIRM_PATH, Parsers::ShipConfirmParser)
    end

    def make_accept_request(accept_builder)
      make_ship_request(accept_builder, SHIP_ACCEPT_PATH, Parsers::ShipAcceptParser)
    end

    def make_ship_request(builder, path, ship_parser)
      response = get_response(path, builder.to_xml)
      ship_parser.new(response.body)
    end

    def build_accept_request_from_confirm(confirm_builder, confirm_response)
      UPS::Builders::ShipAcceptBuilder.new.tap do |builder|
        builder.add_access_request confirm_builder.license_number,
                                   confirm_builder.user_id,
                                   confirm_builder.password
        builder.add_shipment_digest confirm_response.shipment_digest
      end
    end

    # Creates a new access token
    #
    # @return [void]
    def create_token()
      full_url = url + '/security/v1/oauth/token'
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
        fail Exceptions::AuthorizationError, 'Token creation request timed out'
      rescue Excon::Errors::SocketError
        fail Exceptions::AuthorizationError, 'Token creation request failed due to socket error'
      rescue => e
        fail Exceptions::AuthorizationError, "Token creation request failed: #{e.message}"
      end
    end

    # Refreshes the access token once it has expired
    #
    # @param [String] refresh_token Refresh token to use for the request
    # @return [void]
    def refresh_token(refresh_token)
      full_url = url + '/security/v1/oauth/refresh'
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
        fail Exceptions::AuthorizationError, 'Token refresh request timed out'
      rescue Excon::Errors::SocketError
        fail Exceptions::AuthorizationError, 'Token refresh request failed due to socket error'
      rescue => e
        fail Exceptions::AuthorizationError, "Token refresh request failed: #{e.message}"
      end
    end

    # Retrieves the access token, or refreshes it if it has expired
    #
    # @return [String] The access token
    def get_access_token()
      if @token_data.nil?
        fail Exceptions::AuthorizationError, 'No token data found, please call authorize first'
      end

      issued_at = @token_data['issued_at'].to_i
      expires_in = @token_data['expires_in'].to_i
      current_time = Time.now.to_i

      # Token is expired, refresh it
      if issued_at + expires_in <= current_time
        refresh_token(@token_data['refresh_token'])
      end

      @token_data['access_token']
    end

    # Authorizes the connection with the UPS API
    #
    # @param [String] account_number Account number to use for the request
    # @param [String] client_id Client ID to use
    # @param [String] client_secret Client secret to use
    # @return [void]
    def authorize(account_number, client_id, client_secret)
      # Make sure we were given credentials for OAuth
      if params[:account_number].blank? || params[:client_id].blank? || params[:client_secret].blank?
        fail Exceptions::AuthorizationError, 'Missing account_number, client_id, or client_secret'
      end

      self.account_number = account_number
      self.client_id = client_id
      self.client_secret = client_secret

      create_token()
    end
  end
end
