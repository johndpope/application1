class Dealer < ActiveRecord::Base
  include Reversible
  include RegexPatterns
  include CSVAccessor
  include Referable
  include Workable
  validates :name, uniqueness: { scope: [:brand_id, :name] }
  validates :name, :brand_id, presence: true
  validates :email, format: { with: valid_email_pattern, allow_blank: true }
  validates :facebook_url, :google_plus_url, :linkedin_url, :blog_url, :twitter_url, :youtube_url, :yellow_pages_url, url: { allow_blank: true, message: "This is not a valid URL. Valid URL starts with http:// or https://" }
  has_many :sales_calls, -> { order(created_at: :desc) }, class_name: Sales::Call, as: :resource
  has_many :contact_people, -> { order(updated_at: :desc) }, as: :resource, dependent: :destroy
  has_many :sent_emails, -> { order(created_at: :desc) }, as: :resource, dependent: :destroy
  has_many :wordings, as: :resource
  belongs_to :client
  belongs_to :industry

  serialize :"wordings", Array
	has_csv_accessors_for "wordings"

	has_references_for :wordings
	accepts_nested_attributes_for :wordings, allow_destroy: true, reject_if: ->(attributes) { attributes[:source].blank? && attributes[:name].blank? }
  work_queue :dealer_check

  def has_records_in_sales_queue?
    !Dealer.joins("inner join sales_calls on dealers.id = sales_calls.resource_id and sales_calls.resource_type = 'Dealer'").where("dealers.id = ?", self.id).exists?.nil?
  end

  def acceptable_for_sales?
    [target_phone.present?, %w(US CA).include?(country)].all?
  end

  def acceptable_for_dealer_check?
    [target_phone.present?, %w(US CA).include?(country)].all?
  end

  def put_on_sales(run_at = nil, admin_user_company_id = nil, admin_user_id = nil)
    if acceptable_for_sales?
      call = Sales::Call.where(resource: self).first_or_create
      call.put_on_sales(run_at, admin_user_company_id, admin_user_id)
    else
      nil
    end
  end

  def description_wording(w_name)
		self.id.present? ? Wording.where("resource_id = ? AND resource_type = 'Dealer' AND name = ?", self.id, w_name).order("random()").first : nil
	end

	def destroy_description_wordings(w_name)
		Wording.where("resource_id = ? AND resource_type = 'Dealer' AND name = ?", self.id, w_name).destroy_all
	end

  def get_matched_records
    Dealer.where("regexp_replace(
                    regexp_replace(
                      regexp_replace(
                        regexp_replace(
                          lower(dealers.name), '&', 'and', 'g'),
                        ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                    'airconditioning', 'ac', 'g'),
                  'airconditioing', 'ac', 'g') = ? OR (dealers.target_phone IS NOT NULL AND dealers.target_phone <> '' AND regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') = ?) OR (dealers.website IS NOT NULL AND dealers.website <> '' AND regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') = ?)", self.name.downcase
                  .gsub("&", "and")
                  .gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, "")
                  .gsub("airconditioning", "ac")
                  .gsub("airconditioing", "ac"), self.target_phone.to_s.gsub(/[^a-zA-Z0-9]/, ""), self.website.to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, "")).where("dealers.id <> ?", self.id)
  end

  def get_similar_records
    Dealer.where("regexp_replace(
                    regexp_replace(
                      regexp_replace(
                        regexp_replace(
                         regexp_replace(
                          regexp_replace(
                            regexp_replace(
                              regexp_replace(
                                regexp_replace(
                                  lower(dealers.name), '&', 'and', 'g'),
                                ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                              'airconditioning', 'ac', 'g'),
                            'heating', 'htg', 'g'),
                          'conditioning', 'cond', 'g'),
                        'cooling', 'clg', 'g'),
                      'airconditioing', 'ac', 'g'),
                    'aircond', 'ac' ,'g'),
                  'andair', 'andac', 'g') = ? OR (dealers.target_phone IS NOT NULL AND dealers.target_phone <> '' AND regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') = ?) OR (dealers.website IS NOT NULL AND dealers.website <> '' AND regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') = ?)", self.name.downcase
                  .gsub("&", "and")
                  .gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, "")
                  .gsub("airconditioning", "ac")
                  .gsub("heating", "htg")
                  .gsub("conditioning", "cond")
                  .gsub("cooling", "clg")
                  .gsub("airconditioing", "ac")
                  .gsub("aircond", "ac")
                  .gsub("andair", "andac"), self.target_phone.to_s.gsub(/[^a-zA-Z0-9]/, ""), self.website.to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, ""))
  end

  class << self
		def by_id(id)
			return all unless id.present?
			where('dealers.id in (?)', id.strip.split(",").map(&:to_i))
		end

    def by_dealer_check_queue_status(status)
      return all unless status.present?
			where("jobs.status = ? AND jobs.queue = 'dealer_check' AND jobs.completed = TRUE", status)
    end

    def by_dealer_check_queue_admin_user_id(admin_user_id)
      return all unless admin_user_id.present?
			where("jobs.admin_user_id = ? AND jobs.queue = 'dealer_check' AND jobs.completed = TRUE", admin_user_id.to_i)
    end

    def by_dealer_check_queue_days_ago(days_ago)
      return all if !days_ago.present? || days_ago.to_i < 0
			where("jobs.updated_at > ? AND jobs.queue = 'dealer_check' AND jobs.completed = TRUE", days_ago.to_i.days.ago)
    end

    def by_industry_id(industry_id)
			return all unless industry_id.present?
			where('dealers.industry_id in (?)', industry_id.strip.split(",").map(&:to_i))
		end

    def by_name(name)
      return all unless name.present?
      where("regexp_replace(
                      regexp_replace(
                        regexp_replace(
                          regexp_replace(
                            lower(dealers.name), '&', 'and', 'g'),
                          ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                      'airconditioning', 'ac', 'g'),
                    'airconditioing', 'ac', 'g') like ?", "%#{name.downcase.gsub("&", "and")
      .gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, "")
      .gsub("airconditioning", "ac")
      .gsub("airconditioing", "ac").strip}%")
    end

    def by_phone(phone)
      return all unless phone.present?
      phone = phone.to_s.gsub(/[^a-zA-Z0-9]/, "")
      where("regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') = ? OR regexp_replace(dealers.phone1, '[^a-zA-Z0-9]', '', 'g') = ? OR regexp_replace(dealers.phone2, '[^a-zA-Z0-9]', '', 'g') = ? OR regexp_replace(dealers.phone3, '[^a-zA-Z0-9]', '', 'g') = ? OR regexp_replace(dealers.permalease_phone, '[^a-zA-Z0-9]', '', 'g') = ?", phone, phone, phone, phone, phone)
    end

    def by_website(website)
      return all unless website.present?
      website = website.to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, "")
      where("regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') = ?", website)
    end

    def by_email(email)
      return all unless email.present?
      email = email.to_s.downcase.gsub(/[^a-zA-Z0-9]/, "")
      where("regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9]', '', 'g') = ?", email)
    end

    def by_brand_id(brand_id)
			return all unless brand_id.present?
			where('lower(dealers.brand_id) = ?', brand_id.downcase.strip)
		end

    def by_state(state)
			return all unless state.present?
			where('dealers.state = ?', state.strip)
		end

    def by_zipcode(zipcode)
      return all unless zipcode.present?
      where("LEFT(dealers.zipcode, 5) = '#{zipcode}' OR dealers.zipcode_list LIKE '%#{zipcode}%'")
    end

    def get_similar_dealers(dealer, for_public = true)
      dealers = []
      selected_dealers = Dealer.where(id: dealer.id)
      column_names = Dealer.column_names
      column_names.delete('service_areas')
      column_names.delete('zipcode_list')
      column_names.delete('week_hours')
      column_names_string = "dealers." + column_names.join(",dealers.")

      or_conditions = []
      phones = []
      selected_dealers.each do |d|
        phones << d.target_phone.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone1.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone2.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.phone3.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
        phones << d.permalease_phone.to_s.gsub(/[^a-zA-Z0-9]/, "").strip
      end

      phones = phones.compact.reject(&:blank?)
      emails = selected_dealers.map(&:email).map{|e| e.to_s.downcase.gsub(/[^a-zA-Z0-9]/, "").strip}.compact.reject(&:blank?)
      websites = selected_dealers.map(&:website).map{|w| w.to_s.downcase.gsub(/www|https|http/, "").gsub(/[^a-zA-Z0-9]/, "").strip}.compact.reject(&:blank?)

      if phones.present?
      or_conditions << "regexp_replace(dealers.target_phone, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone1, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone2, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.phone3, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}') OR regexp_replace(dealers.permalease_phone, '[^a-zA-Z0-9]', '', 'g') IN ('#{phones.join('\', \'')}')"
      end
      if emails.present?
        emails.each do |e|
          or_conditions << "regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9]', '', 'g') = '#{e}'"
        end
      end
      if websites.present?
        or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.website), 'www|https|http', '', 'g'), '[^a-zA-Z0-9]', '', 'g') IN ('#{websites.join('\', \'')}')"
        or_conditions << "regexp_replace(regexp_replace(LOWER(dealers.email), '[^a-zA-Z0-9@]', '', 'g'), '^.*@+', '', 'g') IN ('#{websites.join('\', \'')}')"
      end

      names = [dealer.name.downcase.gsub('&', 'and').gsub(/,inc| incorporated| inc|&|[^a-zA-Z0-9]/, '').gsub("airconditioning", 'ac').gsub('airconditioing', 'ac').strip]
      unless for_public
        names.each do |name|
          or_conditions << "regexp_replace(
                          regexp_replace(
                            regexp_replace(
                              regexp_replace(
                                lower(dealers.name), '&', 'and', 'g'),
                              ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                          'airconditioning', 'ac', 'g'),
                        'airconditioing', 'ac', 'g') LIKE '%#{name}%'"
        end
      end

      if for_public && (dealer.zipcode.present? || dealer.zipcode_list.present?)
        zip_or_conditions = []
        if dealer.zipcode.present?
          zip_or_conditions << "LEFT(dealers.zipcode, 5) = '#{dealer.zipcode}'"
          zip_or_conditions << "dealers.zipcode_list LIKE '%#{dealer.zipcode}%'"
        end
        if dealer.zipcode_list.present?
          list = eval dealer.zipcode_list
          list.each do |zip|
            zip_or_conditions << "LEFT(dealers.zipcode, 5) = '#{zip}'"
            zip_or_conditions << "dealers.zipcode_list LIKE '%#{zip}%'"
          end
        end

        names_conditions = []
        names.each do |name|
          names_conditions << "regexp_replace(
                          regexp_replace(
                            regexp_replace(
                              regexp_replace(
                                lower(dealers.name), '&', 'and', 'g'),
                              ',inc| incorporated| inc|&|[^a-zA-Z0-9]', '', 'g'),
                          'airconditioning', 'ac', 'g'),
                        'airconditioing', 'ac', 'g') LIKE '%#{name}%'"
        end
        zip_or_conditions = "((" + zip_or_conditions.join(" OR ") + ")" + " AND (" + names_conditions.join(" OR ") + "))"
        or_conditions << zip_or_conditions
      end

      if or_conditions.present?
        dealers = Dealer.unscoped.distinct.select("#{column_names_string}").joins("INNER JOIN jobs ON jobs.resource_id = dealers.id AND jobs.resource_type = 'Dealer'").by_industry_id(dealer.industry_id.to_s).where("dealers.id <> ?", dealer.id).where(or_conditions.join(" OR "))
      end

      if !for_public && (dealer.similar_dealers.present? || dealer.not_similar_dealers.present?)
        dealers = dealers.where("dealers.id NOT IN (?)", dealer.similar_dealers.to_a.map(&:to_i) + dealer.not_similar_dealers.to_a.map(&:to_i))
      end

      dealers
    end
  end
end
