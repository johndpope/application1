crumb :clients do
	link "Clients", clients_path
end

crumb :client do |c|
	parent :clients
	link_title = c.new_record? ? 'New Client' : c.name
	link_url = Rails.application.routes.url_helpers.send("#{c.new_record? ? 'new' : 'edit'}_client_path", (c.new_record? ? nil : c))
	link link_title, link_url
end

crumb :edit_client do |c|
	parent :client, c
	link "Edit Client", edit_client_path(c)
end

crumb :new_client do
	link "New Client"
end

crumb :client_dynamic_text_strings do |c|
	parent :client, c
	link "Dynamic Text Strings", client_aae_templates_path(c)
end

crumb :exclude_aae_templates do |c|
	parent :client, c
	link "Exclude AAE Templates"
end

crumb :client_rendering_settings do |c|
	parent :client, c
	link "Rendering Settings", client_rendering_settings_path(c)
end

crumb :client_blending_settings do |c|
	parent :client, c
	link "Blending Settings", client_blending_settings_path(c)
end

crumb :client_select_image_tags do |c|
	parent :client, c
	link "Image Tag Selection"
end

crumb :client_select_client_specific_image_tags do |c|
	parent :client_select_image_tags, c
	link "Client"
end

crumb :client_select_product_specific_image_tags do |c|
	parent :client_select_image_tags, c
	link "Product"
end

crumb :client_select_subject_video_specific_image_tags do |c|
	parent :client_select_image_tags, c
	link "Subject Video"
end

crumb :products do |c|
	parent :client, c
	link "Products", client_products_path(c)
end

crumb :new_product do |c|
	parent :client, c
	link "New Product"
end

crumb :edit_product do |c,p|
	parent :products, c
	link "Edit Product", edit_client_product_path(c,p)
end

crumb :landing_pages do |c|
	parent :client, c
	link "Landing Pages", client_client_landing_pages_path(c)
end

crumb :new_landing_page do |c|
	parent :client, c
	link "New Landing Page"
end

crumb :edit_landing_page do |c,lp|
	parent :client, c
	link "Edit Landing Page", edit_client_client_landing_page_path(c,lp)
end

crumb :contracts do |c|
	parent :client, c
	link "Contracts", client_contracts_path(c)
end

crumb :new_contract do |c|
	parent :client, c
	link "New Contract"
end

crumb :edit_contract do |c,cn|
	parent :client, c
	link "Edit Contract", edit_client_contract_path(c,cn)
end

crumb :representatives do |c|
	parent :client, c
	link "Representatives", client_representatives_path(c)
end

crumb :new_representative do |c|
	parent :client, c
	link "New Representative"
end

crumb :edit_representative do |c,r|
	parent :client, c
	link "Edit Representative", edit_client_representative_path(c,r)
end

crumb :email_accounts_setups do |c|
	parent :client, c
	link "Accounts Setups", client_email_accounts_setups_path(c)
end

crumb :new_email_accounts_setup do |c|
	parent :client, c
	link "New Accounts Setup"
end

crumb :edit_email_accounts_setup do |c,eas|
	parent :client, c
	link "Edit Accounts Setup", edit_client_email_accounts_setup_path(c,eas)
end

crumb :youtube_setups do |c|
	parent :client, c
	link "Youtube Setups", client_contracts_path(c)
end

crumb :new_youtube_setup do |c|
	parent :client, c
	link "New Youtube Setup"
end

crumb :edit_youtube_setup do |c,ys|
	parent :client, c
	link "Edit Youtube Setup", edit_client_contract_path(c,ys)
end

crumb :source_videos do |c|
	parent :client, c
	link "Subject Videos", client_source_videos_path(c)
end

crumb :donor_videos do |c|
	parent :client, c
	link "Subject Videos", client_donor_videos_path(c)
end


crumb :recipients do |c|
	parent :client, c
	link "Recipients"
end

crumb :donors do |c|
	parent :client, c
	link "Donors"
end

crumb :client_assets do |c|
	parent :client, c
	link "Assets", assets_client_path(c)
end

crumb :youtube_video_search_rank do |c|
	link 'Search Rank', public_youtube_video_search_rank_index_path
end
