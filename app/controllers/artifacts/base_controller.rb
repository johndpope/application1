class Artifacts::BaseController < ApplicationController
  layout 'artifacts'

  before_filter :build_data_page

  protected

    def build_data_page
      @data_page = "#{params[:controller].gsub('/', '_')}_#{params[:action]}"
    end
end
