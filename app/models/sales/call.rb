class Sales::Call < ActiveRecord::Base
  include Workable
  include Reversible
  belongs_to :admin_user
  belongs_to :reassigned_to, class_name: AdminUser, foreign_key: :reassigned_to_id
  belongs_to :resource, polymorphic: true
  # belongs_to :parent, class_name: Sales::Call, primary_key: :sid, foreign_key: :parent_call_sid
  # has_many :children, class_name: Sales::Call, primary_key: :sid, foreign_key: :parent_call_sid
  belongs_to :parent, class_name: Sales::Call, foreign_key: :parent_id
  has_many :children, class_name: Sales::Call, foreign_key: :parent_id
  has_many :comments, -> { order(updated_at: :desc) }, as: :resource, dependent: :destroy
  work_queue :sales

  extend Enumerize
  enumerize :status, :in => Job::SALES_CALLS_STATUSES

  after_save do
    if reschedule_date.present? && reschedule_date_changed?
      reassigned_to_user = reassigned_to || admin_user
      self.resource.put_on_sales(reschedule_date.to_time, reassigned_to_user.try(:admin_user_company_id), reassigned_to_user.try(:id))
    end
  end

  def name
    resource.try(:name)
  end

  def acceptable_for_sales?
    if resource_type == 'Dealer'
      [resource.target_phone.present?, resource.country == 'US'].all?
    else
      false
    end
  end

  def self.report_by_admin_users(days_ago = (Date.today - Time.at(0).to_date).to_i)
    query = "SELECT admin_users.id, admin_users.email, admin_users.first_name, admin_users.last_name, jobs.status, min(sales_calls.duration), max(sales_calls.duration), avg(sales_calls.duration), sum(sales_calls.duration), count(sales_calls.id)
      FROM public.sales_calls
      LEFT OUTER JOIN jobs ON jobs.resource_id = sales_calls.id AND jobs.resource_type = 'Sales::Call'
      LEFT OUTER JOIN admin_users ON admin_users.id = sales_calls.admin_user_id
      WHERE jobs.queue = 'sales' AND jobs.completed = TRUE AND sales_calls.updated_at >= '#{days_ago.days.ago}' AND sales_calls.duration IS NOT NULL
      GROUP BY admin_users.id, admin_users.email, admin_users.first_name, admin_users.last_name, jobs.status;"
    ActiveRecord::Base.connection.execute(query).to_a
  end
end
