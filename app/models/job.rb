class Job < ActiveRecord::Base
  belongs_to :admin_user
  belongs_to :admin_user_company
  belongs_to :resource, polymorphic: true
  belongs_to :parent, class_name: Job, foreign_key: :parent_id
  has_many :children, class_name: Job, foreign_key: :parent_id

  scope :resource, -> resource { where(resource: resource) }

  STATUSES = {
		"Locality not found on site" => 1,
		"Something went wrong" => 2,
    "Started crawling successfully" => 3,
    "Finished crawling successfully" => 4,
    "Parsing failed" => 5,
    "Parsing finished" => 6
	}

  SALES_CALLS_STATUSES = {
    "Interested" => 7,
    "Not Interested" => 8,
    "No Answer" => 9,
    "Call later" => 10,
    "Voicemail" => 14,
    "Presentation" => 15,
    "Contract" => 16,
    "Client" => 17
  }

  DEALER_CHECK_STATUSES = {
    "Checked" => 11,
    "No changes" => 12,
    "No info found" => 13
  }
  extend Enumerize
	enumerize :status, :in => STATUSES.merge(SALES_CALLS_STATUSES).merge(DEALER_CHECK_STATUSES)

  def self.next(queue, resource_type, admin_user)
    Job.where(admin_user_company_id: admin_user.admin_user_company_id, queue: queue, resource_type: resource_type, completed: [nil, false], admin_user_id: [nil, admin_user.id]).where('run_at <= ? OR run_at IS NULL', Time.now).order('admin_user_id NULLS LAST, run_at ASC NULLS LAST, priority ASC NULLS LAST, updated_at DESC').first || Job.where(queue: queue, resource_type: resource_type, completed: [nil, false], admin_user_id: [nil, admin_user.id]).where('run_at <= ? OR run_at IS NULL AND admin_user_company_id IS NULL', Time.now).order('admin_user_id NULLS LAST, run_at ASC NULLS LAST, priority ASC NULLS LAST, updated_at DESC').first
  end

  def assign_to(admin_user, options = {})
      update_attributes(admin_user_id: admin_user.id, active: true)

      if resource.respond_to?("#{queue}_dependencies")
          resource.send("#{queue}_dependencies").each do |child|
              Job.create(parent_id: self.id, resource: child, active: true, admin_user_id: admin_user.id)
          end
      end
  end

  def submit
      update_attributes(completed: true, active: false)
      children.each(&:submit)

      if parent_id.nil? && resource.respond_to?("after_#{queue}")
          resource.send("after_#{queue}")
      end
  end

  def resource_type=(resource_type)
      super(resource_type.to_s.classify.constantize.base_class.to_s)
  end

  def display_name
      resource.try("#{queue}_job_display_name") || resource.try(:display_name)
  end

  def history_items
    Job.where(resource: resource, completed: true).order(created_at: :desc)
  end

  class << self
    def by_dealer_id(id)
			return all unless id.present?
			where('dealers.id in (?)', id.strip.split(",").map(&:to_i))
		end

    def by_status(status)
      return all unless status.present?
			where("jobs.status = ?", status)
    end

    def by_admin_user_id(admin_user_id)
      return all unless admin_user_id.present?
			where("jobs.admin_user_id = ?", admin_user_id.to_i)
    end

    def by_days_ago(days_ago)
      return all if !days_ago.present? || days_ago.to_i < 0
			where("jobs.updated_at > ?", days_ago.to_i.days.ago)
    end

    def by_dealer_name(name)
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

    def by_dealer_brand_id(brand_id)
			return all unless brand_id.present?
			where('lower(dealers.brand_id) = ?', brand_id.downcase.strip)
		end

    def by_dealer_state(state)
			return all unless state.present?
			where('dealers.state = ?', state.strip)
		end

    def report_by_admin_users(queue_name, days_ago = (Date.today - Time.at(0).to_date).to_i)
      query = "SELECT admin_users.id, admin_users.email, admin_users.first_name, admin_users.last_name, jobs.status, min(jobs.running_time), max(jobs.running_time), avg(jobs.running_time), sum(jobs.running_time), count(jobs.id)
        FROM public.jobs
        LEFT OUTER JOIN admin_users ON admin_users.id = jobs.admin_user_id
        WHERE jobs.queue = '#{queue_name}' AND jobs.completed = TRUE AND jobs.updated_at >= '#{days_ago.days.ago}'
        GROUP BY admin_users.id, admin_users.email, admin_users.first_name, admin_users.last_name, jobs.status;"
      ActiveRecord::Base.connection.execute(query).to_a
    end

    def maximum_running_time(last_time = nil)
      Job.where("jobs.running_time > 0 #{'AND jobs.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} ").maximum("jobs.running_time").to_i
    end

    def minimum_running_time(last_time = nil)
      Job.where("jobs.running_time > 0 #{'AND jobs.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} ").minimum("jobs.running_time").to_i
    end

    def average_running_time(last_time = nil)
      Job.where("jobs.running_time > 0 #{'AND jobs.updated_at > ' + "'#{Time.now.utc - last_time.to_i.hours}'" if last_time.present?} ").average("jobs.running_time").to_i
    end
  end
end
