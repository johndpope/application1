require 'rails_helper'

RSpec.describe ClientLandingPage, type: :model do
  let(:client_landing_page) {ClientLandingPage.new}

  describe '.attributes' do
    %w(header_title header_body body_sections footer_title footer_body footer_action_title footer_action_link client_id product_id header_background title meta_description meta_keywords client_landing_page_template_id hosted parked piwik_code subdomain domain piwik_id menu logo header_action_link header_action_title domain_token).each do |a|
      it(a) { expect(client_landing_page).to respond_to(a) }
    end
  end
end
