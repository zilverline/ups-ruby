require "spec_helper"

describe UPS::Builders::OrganisationBuilder do
  subject { UPS::Builders::OrganisationBuilder.new(builder_name) }

  describe "when the name is anything" do
    let(:builder_name) { 'Hamburger' }

    it "disables option to skip Ireland state validation" do
      expect(subject.opts[:skip_ireland_state_validation]).must_equal false
    end
  end
end
