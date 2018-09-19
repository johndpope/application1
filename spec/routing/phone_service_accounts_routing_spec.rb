require "rails_helper"

RSpec.describe PhoneServiceAccountsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/phone_service_accounts").to route_to("phone_service_accounts#index")
    end

    it "routes to #new" do
      expect(:get => "/phone_service_accounts/new").to route_to("phone_service_accounts#new")
    end

    it "routes to #show" do
      expect(:get => "/phone_service_accounts/1").to route_to("phone_service_accounts#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/phone_service_accounts/1/edit").to route_to("phone_service_accounts#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/phone_service_accounts").to route_to("phone_service_accounts#create")
    end

    it "routes to #update" do
      expect(:put => "/phone_service_accounts/1").to route_to("phone_service_accounts#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/phone_service_accounts/1").to route_to("phone_service_accounts#destroy", :id => "1")
    end

  end
end
