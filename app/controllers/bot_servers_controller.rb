class BotServersController < ApplicationController
  before_action :set_bot_server, only: [:show, :edit, :update, :destroy, :turn_daily_activity, :clear_daily_activity_queue, :run_daily_activity, :run_in_batch_daily_activity, :kill_zenno, :start_zenno]
  BOT_SERVERS_DEFAULT_LIMIT = 25

  # GET /bot_servers
  # GET /bot_servers.json
  def index
    params[:limit] = BOT_SERVERS_DEFAULT_LIMIT unless params[:limit].present?

		if params[:filter].present?
			params[:filter][:order] = 'created_at' unless params[:filter][:order].present?
			params[:filter][:order_type] = 'asc' unless params[:filter][:order_type].present?
		else
			params[:filter] = { order: 'created_at', order_type: 'asc' }
		end

		order_by = params[:filter][:order]

    @bot_servers = BotServer.all
      .by_id(params[:id])
      .by_name(params[:name])
      .page(params[:page]).per(params[:limit])
      .order(order_by + ' ' + params[:filter][:order_type])
  end

  # GET /bot_servers/1
  # GET /bot_servers/1.json
  def show
  end

  # GET /bot_servers/new
  def new
    @bot_server = BotServer.new
  end

  # GET /bot_servers/1/edit
  def edit
  end

  # POST /bot_servers
  # POST /bot_servers.json
  def create
    @bot_server = BotServer.new(bot_server_params)

    respond_to do |format|
      if @bot_server.save
        format.html { redirect_to bot_servers_path, notice: 'Bot server was successfully created.' }
        format.json { render action: 'show', status: :created, location: @bot_server }
      else
        format.html { render action: 'new' }
        format.json { render json: @bot_server.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /bot_servers/1
  # PATCH/PUT /bot_servers/1.json
  def update
    respond_to do |format|
      if @bot_server.update(bot_server_params)
        format.html { redirect_to bot_servers_path, notice: 'Bot server was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @bot_server.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bot_servers/1
  # DELETE /bot_servers/1.json
  def destroy
    @bot_server.destroy
    respond_to do |format|
      format.html { redirect_to bot_servers_url }
      format.json { head :no_content }
    end
  end

  def turn_daily_activity
    if @bot_server.daily_activity_enabled
      @bot_server.turn_daily_activity(false)
    else
      @bot_server.turn_daily_activity(true)
    end
    respond_to do |format|
      if @bot_server.save
        format.html { redirect_to bot_servers_url, notice: "Daily activity for bot server '#{@bot_server.name}' was successfully switched." }
      else
        format.html { redirect_to bot_servers_url, alert: "Daily activity for bot server '#{@bot_server.name}' failed to switch." }
      end
    end
  end

  def run_daily_activity
    activities_count = GoogleAccountActivity.fields_updater([@bot_server], true)
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Daily activity for bot server '#{@bot_server.name}' was successfully run with #{activities_count.try(:to_i)} accounts. " }
    end
  end

  def run_in_batch_daily_activity
    if Rails.env.production?
      now = Time.now
      google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE AND bot_servers.id = ?", @bot_server.id)
        .references(google_account:[email_account:[:bot_server]])
      if google_account_activities.size > 0
        GoogleAccountActivity.where("id in (?)", google_account_activities.map(&:id)).update_all({linked: false, updated_at: now})
        ActiveRecord::Base.logger.info "Run daily activity in batch mode for bot server ##{@bot_server.id} at: #{now}"
        start_job_response = Utils.http_get("#{@bot_server.path}/add_activity_count.php", {count: google_account_activities.size}, 3, 10).try(:body).to_s
        ActiveRecord::Base.logger.info "Start job response: #{start_job_response}"
      end
    end
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Daily activity for bot server '#{@bot_server.name}' was successfully run in batch mode with #{google_account_activities.size} accounts." }
    end
  end

  def clear_daily_activity_queue
    @bot_server.clear_daily_activity_queue
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Daily activity queue for bot server '#{@bot_server.name}' was successfully cleared." }
    end
  end

  def turn_off_activity_and_clear_queue
    BotServer.where(human_emulation: true).update_all(daily_activity_enabled: false, recovery_bot_running_status: false, recovery_accounts_activity_enabled: false, recovery_accounts_batch_activity_enabled: false, recovery_answers_checker_enabled: false)
    bot_server_ids = BotServer.where(human_emulation: true).select(:id).pluck(:id)
    if bot_server_ids.present?
      gaa_ids = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("bot_servers.id in (?) AND google_account_activities.linked IS NOT TRUE", bot_server_ids).pluck(:id)
      GoogleAccountActivity.where("id in (?)", gaa_ids).update_all({linked: true, updated_at: Time.now - 2.days}) if gaa_ids.present?
    end
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Daily activity for all bot servers was successfully turned off and cleared." }
    end
  end

  def enable_and_run
    BotServer.where(human_emulation: true).update_all(daily_activity_enabled: true, recovery_bot_running_status: true, recovery_accounts_activity_enabled: true, recovery_accounts_batch_activity_enabled: true, recovery_answers_checker_enabled: true)
    bot_servers = BotServer.where(human_emulation: true)
    activities_count = GoogleAccountActivity.fields_updater(bot_servers, true) if bot_servers.present?
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Daily activity for all bot servers was successfully enabled and run." }
    end
  end

  def start_zenno
    start_response = Net::HTTP.get_response(URI.parse("#{@bot_server.path}/start_zenno.php"))
    notice = if !start_response.is_a?(Net::HTTPSuccess) || start_response.body.to_s == ""
      "Something went wrong while executing script to start Zenno!"
    else
      @bot_server.delay(queue: DelayedJobQueue::OTHER, priority: 0).start_zenno
      "Your request for starting Zenno was received. Please wait for Pushbullet notification within 5 minutes."
    end
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: notice }
    end
  end

  def kill_zenno
    @bot_server.kill_zenno
    respond_to do |format|
      format.html { redirect_to bot_servers_url, notice: "Zenno was successfully killed and daily activity was turned off." }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_bot_server
      @bot_server = BotServer.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def bot_server_params
    	params.require(:bot_server).permit!
    end
end
