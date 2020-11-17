require 'spec_helper'
require 'support/shipping_options'

describe UPS::Connection do
  before do
    Excon.defaults[:mock] = true
  end

  after do
    Excon.stubs.clear
  end

  let(:stub_path) { File.expand_path("../../../stubs", __FILE__) }
  let(:server) { UPS::Connection.new(test_mode: true) }

  describe 'label request' do
    subject do
      server.label do |label_builder|
        label_builder.add_access_request ENV['UPS_LICENSE_NUMBER'], ENV['UPS_USER_ID'], ENV['UPS_PASSWORD']
        label_builder.add_tracking_number '1Z1107YY8567985294'
      end
    end

    describe 'successful label response' do
      before do
        Excon.stub(method: :post) do |params|
          case params[:path]
          when UPS::Connection::LABEL_PATH
            { body: File.read("#{stub_path}/label_success.xml"), status: 200 }
          end
        end
      end

      it 'returns the label data' do
        subject.label_graphic_image.must_be_kind_of File
        subject.label_graphic_image.path.end_with?('.gif').must_equal true
        subject.label_graphic_extension.must_equal '.gif'

        subject.graphic_image.must_be_kind_of File
        subject.graphic_image.path.end_with?('.gif').must_equal true
        subject.graphic_extension.must_equal '.gif'

        subject.html_image.must_be_kind_of File
        subject.html_image.path.end_with?('.gif').must_equal true

        subject.label_html_image.must_be_kind_of File
        subject.label_html_image.path.end_with?('.gif').must_equal true
      end
    end
  end
end
