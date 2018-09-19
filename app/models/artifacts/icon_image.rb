module Artifacts
  class IconImage < Image

    has_attached_file :file,
      styles: {thumb: "250x250>"}
    validates_attachment_content_type :file,
      content_type: ["image/jpg", "image/jpeg", "image/png", "image/gif", "image/svg+xml"]
  end
end
