require 'spec_helper'
require 'tempfile'
require 'support/shipping_options'
require 'byebug'

describe "Mail Innovations" do
  it 'uses ship API with MI services' do
    server = UPS::Connection.new(test_mode: true)

    API_KEY = ENV['UPS_LICENSE_NUMBER']
    USERNAME = ENV['UPS_USER_ID']
    PASSWORD = ENV['UPS_PASSWORD']
    ACCOUNT_NUMBER = ENV['UPS_ACCOUNT_NUMBER']

    ship_response = server.ship do |shipment_builder|
      shipment_builder.add_access_request API_KEY, USERNAME, PASSWORD
      shipment_builder.add_shipper company_name: 'Veeqo Limited',
        phone_number: '01792 123456',
        address_line_1: '11 Wind Street',
        city: 'Swansea',
        state: 'Wales',
        postal_code: 'SA1 1DA',
        country: 'GB',
        shipper_number: ACCOUNT_NUMBER
      shipment_builder.add_ship_from company_name: 'Apple',
        attention_name: 'John Doe',
        phone_number: '01792 123456',
        address_line_1: '1 Infinite Loop',
        city: 'Cupertino',
        state: 'California',
        postal_code: '95014',
        country: 'US',
        shipper_number: ACCOUNT_NUMBER
      shipment_builder.add_ship_to company_name: 'Google Inc.',
        attention_name: 'John Doe',
        phone_number: '01792 123456',
        address_line_1: '1 Infinite Loop',
        city: 'Cupertino',
        state: 'California',
        postal_code: '95014',
        country: 'US'
      shipment_builder.add_package_id '123'
      shipment_builder.add_cost_center 'costcnt123'
      shipment_builder.add_package weight: '0.8',
        unit: 'LBS'
      shipment_builder.add_description 'White coffee mug'
      shipment_builder.add_payment_information '2R466A'
      shipment_builder.add_usps_endorsement '2'
      shipment_builder.add_service 'M4' # returned in rates response
      # shipment_builder.add_service '01'
    end

    byebug
    ship_response.success?.must_equal true
  end
end
