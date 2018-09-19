module CSVAccessor

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods

    def has_csv_accessors_for(*attributes)
      attributes.each do |attribute|
        define_method "#{attribute}_csv" do
          send(attribute).join(', ')
        end

        define_method "#{attribute}_csv=" do |csv|
          send("#{attribute}=", csv.split(/\s*,\s*/))
        end
      end
    end

    def has_sep_accessors_for(*attributes)
      attributes.each do |attribute|
        define_method "#{attribute}_sep" do
          send(attribute).join(', ')
        end

        define_method "#{attribute}_sep=" do |sep|
          send("#{attribute}=", sep.split(/<sep>/))
        end
      end
    end

  end
end
