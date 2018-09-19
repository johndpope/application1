Paperclip.interpolates :base_class do |attachment, style|
  attachment.instance.class.base_class.to_s.underscore.pluralize
end

Paperclip.options[:content_type_mappings] = {
  svg: "image/svg+xml"
}

Paperclip::Attachment.default_options[:use_timestamp] = false
Paperclip::Attachment.default_options[:default_url] = "/missing.png"
