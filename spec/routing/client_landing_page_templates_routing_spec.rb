require "rails_helper"

RSpec.describe ClientLandingPageTemplatesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/client_landing_page_templates").to route_to("client_landing_page_templates#index")
    end

    it "routes to #new" do
      expect(:get => "/client_landing_page_templates/new").to route_to("client_landing_page_templates#new")
    end

    it "routes to #show" do
      expect(:get => "/client_landing_page_templates/1").to route_to("client_landing_page_templates#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/client_landing_page_templates/1/edit").to route_to("client_landing_page_templates#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/client_landing_page_templates").to route_to("client_landing_page_templates#create")
    end

    it "routes to #update" do
      expect(:put => "/client_landing_page_templates/1").to route_to("client_landing_page_templates#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/client_landing_page_templates/1").to route_to("client_landing_page_templates#destroy", :id => "1")
    end

  end
end
