module Workable

  def self.included(base)
    base.extend ClassMethods
  end

  def workable_by?(admin_user)
    Job.where(resource: self, active: true).where.not(admin_user_id: admin_user.id).count.zero?
  end

  module ClassMethods

    def work_queue(name, options = {})
      repeat_after = options[:repeat_after]
      q = name.to_s

      define_method "in_#{q}_queue" do
        conditions = { resource: self, completed: [false, nil], queue: q.to_s }
        Job.where(conditions).first
      end

      define_method "put_on_#{q}" do |run_at = nil, admin_user_company_id = nil, admin_user_id = nil|
        check = "acceptable_for_#{q}?"
        acceptable = self.respond_to?(check) ? self.send(check) : true
        if acceptable
          priority = try("#{q}_priority")
          if job = self.send("in_#{q}_queue")
            unless job.active?
              attrs = { priority: priority }
              attrs[:run_at] = run_at if run_at.present?
              job.update_attributes(attrs)
            end
          elsif job = Job.where(resource: self, queue: q, completed: true).order(updated_at: :desc).first
            if repeat_after.nil? || (repeat_after.present? && (Time.now - job.updated_at) >= repeat_after)
              Job.create(resource: self, priority: priority, queue: q, run_at: run_at, admin_user_company_id: admin_user_company_id, admin_user_id: admin_user_id)
            end
          else
            Job.create(resource: self, priority: priority, queue: q, run_at: run_at, admin_user_company_id: admin_user_company_id, admin_user_id: admin_user_id)
          end
        end
      end
    end
  end
end
