class SocialAccount < ActiveRecord::Base
  include Reversible
  belongs_to :social_item, polymorphic: true
  ACCOUNT_TYPES = { business: 1, personal: 2 }
  extend Enumerize
  enumerize :account_type, :in => ACCOUNT_TYPES, scope: true

	class << self
		def by_id(id)
      return all unless id.present?
      where("social_accounts.id = ?", id.strip)
    end

		def by_social_item_id(social_item_id)
      return all unless social_item_id.present?
      where("social_accounts.social_item_id = ?", social_item_id.strip)
    end

		def by_social_item_type(social_item_type)
			return all unless social_item_type.present?
			where("social_accounts.social_item_type = ?", social_item_type.strip)
		end

    def by_account_type(account_type)
      return all unless account_type.present?
      where("social_accounts.account_type = ?", account_type.to_i)
    end
	end
end
