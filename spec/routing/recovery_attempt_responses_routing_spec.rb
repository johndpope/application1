require "rails_helper"

RSpec.describe RecoveryAttemptResponsesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/recovery_attempt_responses").to route_to("recovery_attempt_responses#index")
    end

    it "routes to #new" do
      expect(:get => "/recovery_attempt_responses/new").to route_to("recovery_attempt_responses#new")
    end

    it "routes to #show" do
      expect(:get => "/recovery_attempt_responses/1").to route_to("recovery_attempt_responses#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/recovery_attempt_responses/1/edit").to route_to("recovery_attempt_responses#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/recovery_attempt_responses").to route_to("recovery_attempt_responses#create")
    end

    it "routes to #update" do
      expect(:put => "/recovery_attempt_responses/1").to route_to("recovery_attempt_responses#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/recovery_attempt_responses/1").to route_to("recovery_attempt_responses#destroy", :id => "1")
    end

  end
end
