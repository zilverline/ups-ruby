require 'spec_helper'

class UPS::Builders::TestShipBuilder < Minitest::Test
  include SchemaPath
  include ShippingOptions

  def setup
    @ship_builder = UPS::Builders::ShipBuilder.new do |builder|
      builder.add_shipper shipper
      builder.add_ship_to ship_to
      builder.add_ship_from shipper
      builder.add_package package
      builder.add_label_specification 'gif', { height: '100', width: '100' }
      builder.add_international_invoice invoice_form
      builder.add_description 'Los Pollo Hermanos'
      builder.add_reference_number reference_number
      builder.add_shipment_delivery_confirmation '2'
      builder.add_shipment_direct_delivery_only
      builder.add_invoice_line_total('12', "GBP")
    end
  end

  def test_validates_against_xsd
    assert_passes_validation schema_path('ShipConfirmRequest.xsd'), @ship_builder.to_xml
  end
end