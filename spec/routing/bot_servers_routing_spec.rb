require "rails_helper"

RSpec.describe BotServersController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/bot_servers").to route_to("bot_servers#index")
    end

    it "routes to #new" do
      expect(:get => "/bot_servers/new").to route_to("bot_servers#new")
    end

    it "routes to #show" do
      expect(:get => "/bot_servers/1").to route_to("bot_servers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/bot_servers/1/edit").to route_to("bot_servers#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/bot_servers").to route_to("bot_servers#create")
    end

    it "routes to #update" do
      expect(:put => "/bot_servers/1").to route_to("bot_servers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/bot_servers/1").to route_to("bot_servers#destroy", :id => "1")
    end

  end
end
