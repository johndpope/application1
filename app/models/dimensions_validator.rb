class DimensionsValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    temp_file = value.queued_for_write[:original]
    unless temp_file.nil?
      dimensions = Paperclip::Geometry.from_file(temp_file)
      width = options[:minimum_width]
      height = options[:minimum_height]

      record.errors[attribute] << "Dimensions are too small. For a good quality background please upload a larger image. Minimum width: #{width}px, minimum height: #{height}px" if dimensions.width < width || dimensions.height < height
    end
  end
end