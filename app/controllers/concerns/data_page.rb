module DataPage
	extend ActiveSupport::Concern

	included do
    before_filter :build_data_page
  end

  def build_data_page
    @data_page = "#{params[:controller].gsub('/', '_')}_#{params[:action]}"
		@body_class = "#{params[:controller].gsub('/', '_')} #{params[:action]}"
  end
end
