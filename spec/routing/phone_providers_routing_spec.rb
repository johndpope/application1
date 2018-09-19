require "rails_helper"

RSpec.describe PhoneProvidersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/phone_providers").to route_to("phone_providers#index")
    end

    it "routes to #new" do
      expect(:get => "/phone_providers/new").to route_to("phone_providers#new")
    end

    it "routes to #show" do
      expect(:get => "/phone_providers/1").to route_to("phone_providers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/phone_providers/1/edit").to route_to("phone_providers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/phone_providers").to route_to("phone_providers#create")
    end

    it "routes to #update" do
      expect(:put => "/phone_providers/1").to route_to("phone_providers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/phone_providers/1").to route_to("phone_providers#destroy", :id => "1")
    end

  end
end
