require 'spec_helper'

describe UPS::Connection do
  include ShippingOptions

  before do
    Excon.defaults[:mock] = true
  end

  after do
    Excon.stubs.clear
  end

  let(:stub_path) { File.expand_path("../../../stubs", __FILE__) }
  let(:server) { UPS::Connection.new(test_mode: true) }

  describe "if requesting rates" do
    before do
      Excon.stub({:method => :post}) do |params|
        case params[:path]
        when UPS::Connection::RATE_PATH
          {body: File.read("#{stub_path}/rates_negotiated_success.xml"), status: 200}
        end
      end
    end

    subject do
      server.authorize ENV['UPS_ACCOUNT_NUMBER'], ENV['UPS_CLIENT_ID'], ENV['UPS_CLIENT_SECRET']
      server.rates do |rate_builder|
        rate_builder.add_shipper shipper
        rate_builder.add_ship_from shipper
        rate_builder.add_ship_to ship_to
        rate_builder.add_package package
        rate_builder.add_rate_information
      end
    end

    it "should return neotiated rates" do
      expect(subject.rated_shipments).wont_be_empty
      expect(subject.rated_shipments).must_equal [
        {
          :service_code=>"11",
          :service_name=>"UPS Standard",
          :warnings=>["Your invoice may vary from the displayed reference rates"],
          :total=>"24.78"

        },
        {
          :service_code=>"65",
          :service_name=>"UPS Saver",
          :warnings=>["Your invoice may vary from the displayed reference rates"],
          :total=>"45.15"
        },
        {
          :service_code=>"54",
          :service_name=>"Express Plus",
          :warnings=>["Your invoice may vary from the displayed reference rates"],
          :total=>"80.89"
        },
        {
          :service_code=>"07",
          :service_name=>"Express",
          :warnings=>["Your invoice may vary from the displayed reference rates"],
          :total=>"47.08"
        }
      ]
    end
  end
end
