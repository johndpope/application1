require "rails_helper"

RSpec.describe PhoneServicesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/phone_services").to route_to("phone_services#index")
    end

    it "routes to #new" do
      expect(:get => "/phone_services/new").to route_to("phone_services#new")
    end

    it "routes to #show" do
      expect(:get => "/phone_services/1").to route_to("phone_services#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/phone_services/1/edit").to route_to("phone_services#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/phone_services").to route_to("phone_services#create")
    end

    it "routes to #update" do
      expect(:put => "/phone_services/1").to route_to("phone_services#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/phone_services/1").to route_to("phone_services#destroy", :id => "1")
    end

  end
end
