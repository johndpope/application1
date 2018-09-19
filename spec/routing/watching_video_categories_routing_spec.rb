require "rails_helper"

RSpec.describe WatchingVideoCategoriesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/watching_video_categories").to route_to("watching_video_categories#index")
    end

    it "routes to #new" do
      expect(:get => "/watching_video_categories/new").to route_to("watching_video_categories#new")
    end

    it "routes to #show" do
      expect(:get => "/watching_video_categories/1").to route_to("watching_video_categories#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/watching_video_categories/1/edit").to route_to("watching_video_categories#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/watching_video_categories").to route_to("watching_video_categories#create")
    end

    it "routes to #update" do
      expect(:put => "/watching_video_categories/1").to route_to("watching_video_categories#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/watching_video_categories/1").to route_to("watching_video_categories#destroy", :id => "1")
    end

  end
end
