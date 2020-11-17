require 'spec_helper'

class UPS::Builders::TestLabelRecoveryRequestBuilder < Minitest::Test
  include SchemaPath
  include ShippingOptions

  def setup
    @label_recovery_request_builder = UPS::Builders::LabelRecoveryRequestBuilder.new do |builder|
      builder.add_access_request ENV['UPS_LICENSE_NUMBER'], ENV['UPS_USER_ID'], ENV['UPS_PASSWORD']
      builder.add_tracking_number('1Z8Y7F409115810727')
    end
  end

  def test_validates_against_xsd
    pp @label_recovery_request_builder.to_xml
    assert_passes_validation schema_path('LabelRecoveryRequest.xsd'), @label_recovery_request_builder.to_xml
  end
end
