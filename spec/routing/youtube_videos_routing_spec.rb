require "rails_helper"

RSpec.describe YoutubeVideosController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/youtube_videos").to route_to("youtube_videos#index")
    end

    it "routes to #new" do
      expect(:get => "/youtube_videos/new").to route_to("youtube_videos#new")
    end

    it "routes to #show" do
      expect(:get => "/youtube_videos/1").to route_to("youtube_videos#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/youtube_videos/1/edit").to route_to("youtube_videos#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/youtube_videos").to route_to("youtube_videos#create")
    end

    it "routes to #update" do
      expect(:put => "/youtube_videos/1").to route_to("youtube_videos#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/youtube_videos/1").to route_to("youtube_videos#destroy", :id => "1")
    end

  end
end
