ActiveAdmin.register CaseType do
  menu parent: 'Source Videos'
  
  sortable tree: true, sorting_attribute: :name, collapsible: true, start_collapsed: true

  index as: :sortable do
    label :name
    actions
  end

  collection_action :replicate, method: :post do
    CaseType.replicate
    redirect_to :action => :index, :notice => "Case Types have been successfully replicated."
  end

  action_item only: :index do
    link_to 'Replicate', replicate_admin_case_types_path, method: :post
  end
end
