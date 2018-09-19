require 'rails_helper'

RSpec.describe ClientLandingPageTemplate, type: :model do
  let(:client_landing_page_template) {ClientLandingPageTemplate.new}

  describe '.attributes' do
    %w(name file_name preview).each do |a|
      it(a) { expect(client_landing_page_template).to respond_to(a) }
    end
  end
end
