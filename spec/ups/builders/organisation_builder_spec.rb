require "spec_helper"

describe UPS::Builders::OrganisationBuilder do
  subject { UPS::Builders::OrganisationBuilder.new(builder_name) }

  describe "when the name is 'SoldTo'" do
    let(:builder_name) { 'SoldTo' }

    it "enables option to skip Ireland state validation" do
      subject.opts[:skip_ireland_state_validation].must_equal true
    end
  end

  describe "when the name is anything else" do
    let(:builder_name) { 'Hamburger' }

    it "disables option to skip Ireland state validation" do
      subject.opts[:skip_ireland_state_validation].must_equal false
    end
  end
end
