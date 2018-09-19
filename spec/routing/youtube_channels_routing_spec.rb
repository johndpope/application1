require "rails_helper"

RSpec.describe YoutubeChannelsController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/youtube_channels").to route_to("youtube_channels#index")
    end

    it "routes to #new" do
      expect(:get => "/youtube_channels/new").to route_to("youtube_channels#new")
    end

    it "routes to #show" do
      expect(:get => "/youtube_channels/1").to route_to("youtube_channels#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/youtube_channels/1/edit").to route_to("youtube_channels#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/youtube_channels").to route_to("youtube_channels#create")
    end

    it "routes to #update" do
      expect(:put => "/youtube_channels/1").to route_to("youtube_channels#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/youtube_channels/1").to route_to("youtube_channels#destroy", :id => "1")
    end

  end
end
