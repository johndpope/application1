crumb :templates do
	link 'Templates', templates_root_path
end

crumb :image_templates do
  link t("templates.image_template.image_templates"), templates_image_templates_path
  parent :templates
end

crumb :aae_templates do
	link 'AAE Templates'
	parent :templates
end

crumb :aae_template_texts do
	link 'Texts'
	parent :aae_templates
end

crumb :correct_static_texts do
	link 'Correct Static Texts'
	parent :aae_template_texts
end
