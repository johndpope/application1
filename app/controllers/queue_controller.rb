class QueueController < ApplicationController
  before_action :set_job, only: [:edit, :submit, :process_again, :unlock]
  DEFAULT_PAGE_LIMIT = 25
  PHONE_DEFAULT_LIMIT = 25

  def index
    unless params[:limit].present?
      params[:limit] = DEFAULT_PAGE_LIMIT
      params[:scheduled_limit] = DEFAULT_PAGE_LIMIT
      params[:admin_user_id] = current_admin_user.id unless params[:admin_user_id].present?
      params[:scheduled_admin_user_id] = current_admin_user.id unless params[:scheduled_admin_user_id].present?
    end

		if params[:filter].present?
			params[:filter][:order] = 'updated_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'desc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'updated_at', order_type: 'desc' }
		end
    order_by = if %w(name city state).include?(params[:filter][:order])
      'dealers.' + params[:filter][:order]
    else
      'jobs.' + params[:filter][:order]
    end
    @completed_jobs = if params[:name] == 'sales'
      Job.joins("inner join sales_calls on sales_calls.id = jobs.resource_id and jobs.resource_type = 'Sales::Call'
  inner join dealers on sales_calls.resource_id = dealers.id").where("jobs.queue = ? AND jobs.completed = TRUE", params[:name])
      .by_dealer_id(params[:dealer_id])
      .by_dealer_name(params[:dealer_name])
      .by_dealer_brand_id(params[:dealer_brand_id])
      .by_dealer_state(params[:dealer_state])
      .by_status(params[:job_status])
      .by_admin_user_id(params[:admin_user_id])
      .by_days_ago(params[:job_days_ago])
      .order(order_by + ' ' + params[:filter][:order_type]).page(params[:page]).per(params[:limit])
    else
      Job.distinct.where(queue: params[:name], completed: true)
      .by_status(params[:job_status])
      .by_admin_user_id(params[:admin_user_id])
      .by_days_ago(params[:job_days_ago])
      .order("jobs.updated_at DESC").page(params[:page]).per(params[:limit])
    end
    respond_to do |format|
      format.html {
        @scheduled_jobs = Job.distinct.where("jobs.run_at IS NOT NULL AND jobs.completed IS NOT TRUE AND jobs.active IS NOT TRUE AND jobs.queue = ?", params[:name])
          .by_status(params[:scheduled_job_status])
          .by_admin_user_id(params[:scheduled_admin_user_id])
          .order("jobs.run_at ASC NULLS LAST").page(params[:page]).per(params[:limit])
      }
      format.js { render :index, locals: {jobs: @completed_jobs, queue: params[:queue]} }
    end
  end

  def scheduled_jobs
    unless params[:scheduled_limit].present?
      params[:scheduled_limit] = DEFAULT_PAGE_LIMIT
    end

		if params[:filter].present?
			params[:filter][:order] = 'run_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'run_at', order_type: 'asc' }
		end
    order_by = if %w(name city state).include?(params[:filter][:order])
      'dealers.' + params[:filter][:order]
    else
      'jobs.' + params[:filter][:order]
    end
    @scheduled_jobs = if params[:name] == 'sales'
      Job.joins("inner join sales_calls on sales_calls.id = jobs.resource_id and jobs.resource_type = 'Sales::Call' inner join dealers on sales_calls.resource_id = dealers.id").where("jobs.completed IS NOT TRUE AND jobs.active IS NOT TRUE AND queue = 'sales'")
        .by_dealer_id(params[:scheduled_dealer_id])
        .by_dealer_name(params[:scheduled_dealer_name])
        .by_dealer_brand_id(params[:scheduled_dealer_brand_id])
        .by_dealer_state(params[:scheduled_dealer_state])
        .by_status(params[:scheduled_job_status])
        .by_admin_user_id(params[:scheduled_admin_user_id])
        .order("jobs.run_at ASC NULLS LAST, " + order_by + ' ' + params[:filter][:order_type]).page(params[:page]).per(params[:scheduled_limit])
      else
        Job.distinct.where("jobs.completed IS NOT TRUE AND jobs.active IS NOT TRUE AND jobs.queue = ?", params[:name])
        .by_status(params[:scheduled_job_status])
        .by_admin_user_id(params[:scheduled_admin_user_id])
        .order("jobs.run_at ASC NULLS LAST, " + order_by + ' ' + params[:filter][:order_type]).page(params[:page]).per(params[:scheduled_limit])
      end
    respond_to do |format|
      format.js { render :scheduled_jobs, locals: {scheduled_jobs: @scheduled_jobs, queue: params[:queue]} }
    end
  end

  def next_record
    resource_type = case params[:name]
    when 'geobase_localities_init'
      Geobase::Locality.to_s
    when 'sales'
      Sales::Call.to_s
    when 'dealer_check'
      Dealer.to_s
    else
      nil
    end

    if resource_type.nil?
      redirect_to index_queue_path(name: params[:name])
    else
      @job = Job.next(params[:name], resource_type, current_admin_user)
      if @job
        @job.assign_to(current_admin_user)
        if params[:name] == 'geobase_localities_init'
          @job.submit
          geobase_locality = @job.resource
          render json: {id: geobase_locality.id, name: geobase_locality.name, region: geobase_locality.primary_region.try(:name), country: geobase_locality.country.name,  queue_status: "active"}
        elsif params[:name] == 'sales'
          @resource_id = @job.resource_id
          @resource_type = @job.resource_type
          @contact_person_resource_id = @job.resource.resource_id
          @contact_person_resource_type = @job.resource.resource_type
          @sent_email_resource_id = @job.resource.resource_id
          @sent_email_resource_type = @job.resource.resource_type
          @receiver = @job.resource.resource.try(:email)
          @subject = "Follow up call"
          redirect_to edit_queue_path(id: @job.id, name: params[:name])
        else
          redirect_to edit_queue_path(id: @job.id, name: params[:name])
        end
      else
        if params[:name] == 'geobase_localities_init'
          render json: {queue_status: "empty"}
        else
          redirect_to index_queue_path(name: params[:name]), alert: 'Queue is empty.'
        end
      end
    end
  end

  def unlock
    if params[:now].to_s == "true"
      @job.assign_to(current_admin_user)
    else
      @job.admin_user = current_admin_user
      @job.save
    end
    if params[:name] == 'sales'
      @resource_id = @job.resource_id
      @resource_type = @job.resource_type
      @contact_person_resource_id = @job.resource.resource_id
      @contact_person_resource_type = @job.resource.resource_type
      @sent_email_resource_id = @job.resource.resource_id
      @sent_email_resource_type = @job.resource.resource_type
      @receiver = @job.resource.resource.try(:email)
      @subject = "Follow up call"
      redirect_to edit_queue_path(id: @job.id, name: params[:name])
    else
      redirect_to edit_queue_path(id: @job.id, name: params[:name])
    end
  end

  def edit
    if @job.admin_user_id != current_admin_user.id && !@job.completed && @job.active
      redirect_to index_queue_path(name: params[:name]), alert: "Access denied for record ##{@job.id}"
    elsif params[:name] == 'sales'
      @resource_id = @job.resource_id
      @resource_type = @job.resource_type
      @contact_person_resource_id = @job.resource.resource_id
      @contact_person_resource_type = @job.resource.resource_type
      @sent_email_resource_id = @job.resource.resource_id
      @sent_email_resource_type = @job.resource.resource_type
      @receiver = @job.resource.resource.try(:email)
      @subject = "Follow up call"
      if !@job.completed && @job.active
        @job.updated_at = Time.now
        @job.save
      end
    else

    end
  end

  def submit
    respond_to do |format|
      @job.status = params[:job][:status] if params[:job].present? && params[:job][:status].present?
      time = Time.at(Time.now - @job.updated_at).utc
      @job.running_time = time.hour*3600 + time.min*60 + time.sec
      @job.submit
      if @job.resource_type == Sales::Call.to_s
        sales_call = @job.resource
        if params[:reschedule_date].present?
          time = if params[:utc_offset].present?
            sign = params[:utc_offset][0] == "+" ? "-" : "+"
            time = sign + Utils.seconds_to_time(params[:utc_offset].to_i.abs * 60)
          else
            "#{Time.now.utc.strftime('%H:%M %p')} +00:00"
          end
          sales_call.reschedule_date = DateTime.strptime("#{params[:reschedule_date]} #{time}", '%m/%d/%Y %H:%M %p %:z')
          sales_call.reassigned_to_id = params[:job][:reassigned_to].to_i if params[:job].present? && params[:job][:reassigned_to].present?
        end
        start_time = params[:start_time].to_i
        end_time = params[:end_time].to_i
        sales_call.status = @job.status
        sales_call.start_time = Time.at(start_time / 1000.0) if start_time > 0
        sales_call.end_time = Time.at(end_time / 1000.0) if end_time > 0
        if ![start_time, end_time].include?(0) && end_time > start_time
          sales_call.duration = (end_time - start_time) / 1000
        end
        sales_call.admin_user = current_admin_user
        sales_call.save
      end

      format.html {
        if params[:next].present?
          redirect_to next_record_queue_path(name: params[:name])
        else
          redirect_to index_queue_path(name: params[:name])
        end
      }
    end
  end

  def process_again
    new_job = nil
    if @job.completed
      new_job = if params[:name] == 'sales'
        @job.resource.resource.put_on_sales(nil, nil, current_admin_user.id)
      else
        @job.resource.send("put_on_#{params[:name]}", nil, nil, current_admin_user.id)
      end
    end
    if new_job.is_a?(Job)
      redirect_to edit_queue_path(name: params[:name], id: new_job.id)
    else
      redirect_to index_queue_path(name: params[:name]), alert: "Access denied for this record"
    end
  end

  def set_status
    if params[:name].present? && params[:resource_id].present? && params[:status].present?
      job = Job.where(queue: params[:name], resource_id: params[:resource_id]).order(created_at: :desc).first
      saved = if job.present?
        job.status = params[:status]
        job.run_at = Time.now if job.status.try(:value) == Job.status.find_value("Started crawling successfully").value && job.queue == 'geobase_localities_init'
        if Job.status.find_value("Finished crawling successfully").value.to_s == params[:status].to_s && job.run_at.present?
          time = Time.at(Time.now - job.run_at).utc
          job.running_time = time.hour*3600 + time.min*60 + time.sec
        end
        if job.save
          if job.status.value == Job.status.find_value("Finished crawling successfully").value && job.queue == 'geobase_localities_init'
            json_full_path = (Setting.get_value_by_name("EmailAccount::BOT_URL") + Setting.get_value_by_name("Wording::TRIPADVISOR_JSON_PATH")).gsub("<locality_id>", job.resource_id.to_s)
            Delayed::Job.enqueue Crawler::CrawlerAddInfoJob.new(job.resource_id, json_full_path), queue: DelayedJobQueue::CRAWLER_ADD_INFO
          end
          render json: {status: 200}
        else
          render json: {status: 500, messages: "Status was not saved"}, status: 500
        end
      else
        render json: {status: 404, messages: "Not found"}, status: 404
      end
    else
      render json: {status: 500, messages: "Not enough params for saving"}, status: 500
    end
  end

  def report_by_admin_users
    queue_name = params[:name]
    if %w(sales dealer_check).include?(queue_name)
      params[:days_ago] = 1 unless params[:days_ago].present?
      @records = params[:days_ago].to_i > 0 ? Job.report_by_admin_users(queue_name, params[:days_ago].to_i) : Job.report_by_admin_users(queue_name)
      calls_records = params[:days_ago].to_i > 0 ? Sales::Call.report_by_admin_users(params[:days_ago].to_i) : Sales::Call.report_by_admin_users
      @report = []

      ids = @records.map{|e| e["id"]}.uniq
      ids.each do |id|
        row = {}
        row["id"] = id
        by_id_rows = @records.select {|e| e["id"] == id}
        by_id_rows_calls = calls_records.select {|e| e["id"] == id}
        row["email"] = by_id_rows.first["email"]
        row["first_name"] = by_id_rows.first["first_name"]
        row["last_name"] = by_id_rows.first["last_name"]
        row["by_status_stat"] = by_id_rows
        row["by_status_stat_calls"] = by_id_rows_calls
        @report << row
      end
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_job
      @job = Job.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def job_params
      params.require(:job).permit!
    end
end
