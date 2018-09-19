module TooltipsHelper
  def tooltip_by_field(table_name:nil, table_column:nil, tooltip_text:nil)

    raise "Enter table_name/table_column" if ((!table_name.blank? && table_column.blank?) || (table_name.blank? && !table_column.blank?))
    options = {}

    if !table_name.blank? && !table_column.blank?
      tooltip = Tooltip.where(table_name: table_name, table_column: table_column).first
      options[:tooltip] = tooltip
      options[:tooltip_text] = tooltip.value unless tooltip.blank?
      options[:is_static] = false
    elsif !tooltip_text.blank?
      options[:tooltip_text] = tooltip_text
      options[:is_static] = true
    end
    render partial: "clients/tooltip_box", locals: {options: options}
  end
end
