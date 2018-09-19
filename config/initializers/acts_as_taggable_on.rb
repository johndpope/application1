ActsAsTaggableOn::Tag.class_eval do
  translates :name
end

ActsAsTaggableOn::GenericParser.class_eval do
  def initialize(tag_list)
		unless tag_list.is_a? Array
			if tag_list.is_a? String
				tag_list = tag_list.split(',')
			elsif tag_list.nil?
				[]
			else
				raise "tag_list cannot be processed because it's neither Array nor String"
			end
		end
    @tag_list = tag_list.map(&:strip).reject(&:empty?).uniq{|e| e.mb_chars.downcase.to_s}.join(",")
  end

  def parse
    TagList.new.tap do |tag_list|
      tag_list.add @tag_list.split(',').map(&:strip).reject(&:empty?).uniq{|e| e.mb_chars.downcase.to_s}
    end
  end
end
