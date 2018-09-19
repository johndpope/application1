module Paragraphable
  def self.included(base)
    base.extend ClassMethods
    base.class_eval do
      has_many :paragraphs, -> { order(position: :asc) }, as: :resource
    end
  end

  module ClassMethods
    def has_paragraphs_for(group)
      association = "#{group}_paragraphs".to_sym
      has_many association, -> { where(scope: group).order(position: :asc) },
        class_name: 'Paragraph', as: :resource,
        after_add: ->(o, p) { p.scope = group }

      define_method group do |options = {}|
        items = send(association)
        items = items.shuffle if options[:shuffle] == true
        items.map { |p|
          if options[:spin] == true && p.spintax.present?
            p.spintax.extend SpintaxParser
            p.spintax.unspin
          else
            p.body
          end
        }.join(" ")
      end
    end
  end
end
