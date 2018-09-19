class InvoiceItem < ActiveRecord::Base
  include Reversible
  belongs_to :invoice
  belongs_to :resource, polymorphic: true
  validates :quantity, :unit_price, :name, presence: :true
  INVOICE_ITEM_TYPES = { down_payment: 1, other: 2 }
  extend Enumerize
  enumerize :invoice_item_type, :in => INVOICE_ITEM_TYPES
end
