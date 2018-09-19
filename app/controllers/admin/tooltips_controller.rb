class Admin::TooltipsController < Admin::BaseController
  def index
    client_ref = []
    client_reflections = Client.reflections
    keys_to_ignore = [:blended_videos]
    keys_to_ignore.each {|k| client_reflections.delete(k)}
    client_reflections.each_key {|k| client_ref.push(client_reflections[k.to_sym].table_name) }
    @tables = client_ref.reject{|e| Tooltip::BLACK_LIST.include? e}.uniq
    @tables.push("templates_aae_projects", "templates_aae_project_texts", "templates_aae_project_images")
    @current_table_name = params[:table_name] || @tables.first.to_s

    @tooltipped_table_columns = Tooltip.where(table_name: @current_table_name)
    @available_table_columns = ActiveRecord::Base.connection.select_values("
      SELECT column_name
      FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name ='#{@current_table_name}'
      ORDER BY table_name").
      reject{|v|%w(created_at updated_at).include? v}.
      reject{|v|Tooltip::EXCLUDED_FIELDS[@current_table_name.to_sym].to_a.include? v}
  end

  def create
    if (params[:tooltip][:value].blank? && !params[:tooltip][:id].blank?)
      @tooltip = Tooltip.find_by_id(params[:tooltip][:id])
      @tooltip.destroy! unless @tooltip.blank?
    else
      @tooltip = Tooltip.where(table_name: params[:tooltip][:table_name], table_column: params[:tooltip][:table_column]).first_or_initialize
      @tooltip.value = params[:tooltip][:value]
      @tooltip.save
    end
  end

end
