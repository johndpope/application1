require 'open-uri'
# This controller was created for Victor's bot, but not for public views
class GoogleAccountActivitiesController < ApplicationController
  before_action :set_google_account_activity,
    only: [:show, :edit, :update, :destroy, :touch, :recovery_attempt_answer, :recovery_attempt_response, :bot_action, :fetch_field, :create_facebook_account, :create_google_plus_account, :add_youtube_strike, :youtube_audio_library]
  skip_before_filter :verify_authenticity_token, :only => [:add_youtube_strike, :youtube_audio_library]

  def index
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    @google_account_activities = if params[:recovery_attempt] == true.to_s
        now = Time.now.in_time_zone('Eastern Time (US & Canada)')
        # Add in where days from last attempt
        # date_from = if Setting.get_value_by_name('GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS') == false.to_s
        #   date = now
        #   date - date.hour.hours - date.min.minutes - date.sec.seconds + 1.second
        # else
        #   Setting.find_by_name('GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS').updated_at
        # end
        date_from = bot_server.recovery_bot_running_status_updated_at
        if now.hour == 3
          #regular
          GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
            .where("email_accounts.is_active = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
              AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] <> ? AND email_accounts.bot_server_id = ?", GoogleAccountActivity::RECOVERY_ANSWERS["Positive answer"], bot_server.id)
            .references(google_account:[email_account:[:bot_server]]).order("random()")
        else
          #something wrong - retry
          GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
            .where("email_accounts.is_active = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
              AND (google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] < ?
              OR google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] IS NULL)
              AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] <> ? AND email_accounts.bot_server_id = ?", date_from.getgm, GoogleAccountActivity::RECOVERY_ANSWERS["Positive answer"], bot_server.id)
            .references(google_account:[email_account:[:bot_server]])
        end
      elsif params[:is_active] == false.to_s
        GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("email_accounts.is_active = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.bot_server_id = ?", bot_server.id)
        .order("google_account_activities.updated_at asc").references(google_account:[email_account:[:bot_server]])
      elsif params[:recovery_answers_checker] == true.to_s
        time_now = Time.now.in_time_zone('Eastern Time (US & Canada)')
        if Utils.open_for_business?(false, time_now)
          if time_now.hour == bot_server.start_business_working_hour
            #clear daily online time
            GoogleAccountActivity.update_all(today_online_time: 0)
            bot_server.recovery_bot_running_status_updated_at = Time.now
            bot_server.save
          end
        end
        date_from = bot_server.recovery_bot_running_status_updated_at
        accounts_for_checker = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
          .where("email_accounts.is_active = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
            AND ((google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] > ?
            AND google_account_activities.recovery_answer[array_length(google_account_activities.recovery_answer, 1)] in (?)) OR (google_account_activities.recovery_attempt[array_length(google_account_activities.recovery_attempt, 1)] > ? AND google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] < ?))", date_from.getgm, [GoogleAccountActivity::RECOVERY_ANSWERS["No answer"], GoogleAccountActivity::RECOVERY_ANSWERS["Wait for the result"], GoogleAccountActivity::RECOVERY_ANSWERS["Authentification failed"]], date_from.getgm, date_from.getgm)
          .order("google_account_activities.recovery_answer_date[array_length(google_account_activities.recovery_answer_date, 1)] DESC NULLS FIRST")
          .references(google_account:[email_account:[:bot_server]])
        ActiveRecord::Base.logger.info "Inactive accounts for checker: #{accounts_for_checker.size}"
        accounts_for_checker
      elsif params[:youtube_business_channels_manually] == true.to_s
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.recovery_phone_assigned = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND (youtube_channels.is_verified_by_phone=FALSE OR youtube_channels.filled = FALSE) AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.youtube_channels.each do |yc|
            gaas << gaa if yc.channel_type == "business" && (yc.acceptable_for_creation? || yc.acceptable_for_verification? || yc.acceptable_for_filling?)
          end
        end
        gaas = gaas.uniq
      elsif params[:youtube_website_associate_manually] == true.to_s
        gaas = GoogleAccountActivity.joins("LEFT JOIN google_accounts ON google_accounts.id = google_account_activities.google_account_id LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id LEFT JOIN ip_addresses ON email_accounts.ip_address_id = ip_addresses.id LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id LEFT JOIN youtube_videos ON youtube_videos.youtube_channel_id = youtube_channels.id LEFT JOIN associated_websites ON associated_websites.youtube_channel_id = youtube_channels.id LEFT JOIN bot_servers ON bot_servers.id = email_accounts.bot_server_id and email_accounts.email_item_type = 'GoogleAccount'").where("email_accounts.is_active = true AND youtube_channels.is_active = true AND youtube_channels.channel_type = ? AND associated_websites.linked IS NOT TRUE AND associated_websites.ready = true AND email_accounts.bot_server_id = ?", YoutubeChannel::CHANNEL_TYPES[:business], bot_server.id).uniq
      elsif params[:youtube_videos_manually] == true.to_s
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |yv|
              gaas << gaa if yc.channel_type == "business" && yv.acceptable_for_uploading?
            end
          end
        end
        gaas = gaas.uniq
      elsif params[:youtube_video_info_manually] == true.to_s
        gaas = GoogleAccountActivity.joins("LEFT JOIN google_accounts ON google_accounts.id = google_account_activities.google_account_id
          LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
          LEFT JOIN ip_addresses ON email_accounts.ip_address_id = ip_addresses.id
          LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id
          LEFT JOIN youtube_videos ON youtube_videos.youtube_channel_id = youtube_channels.id
          LEFT JOIN bot_servers ON bot_servers.id = email_accounts.bot_server_id
          and email_accounts.email_item_type = 'GoogleAccount'")
          .where("email_accounts.is_active = true AND youtube_videos.ready = true AND youtube_videos.linked = false AND email_accounts.bot_server_id = ?", bot_server.id)
        gaas = gaas.uniq
      elsif params[:youtube_video_cards_manually] == true.to_s
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |yv|
              yv.youtube_video_cards.each do |yvc|
                gaas << gaa if yvc.acceptable_for_adding?
              end
            end
          end
        end
        gaas = gaas.uniq
      elsif params[:adwords_campaigns_manually] == true.to_s
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.adwords_campaigns.each do |ac|
            gaas << gaa if ac.acceptable_for_adding?
          end
        end
        gaas = gaas.uniq
      elsif params[:adwords_campaign_groups_manually]
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.adwords_campaigns.each do |ac|
            ac.adwords_campaign_groups.each do |acg|
              gaas << gaa if acg.acceptable_for_adding?
            end
          end
        end
        gaas = gaas.uniq
      elsif params[:call_to_action_overlays_manually]
        google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
        .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
          AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
          AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND email_accounts.bot_server_id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

        google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_id in (?)", google_accounts_ids)
        .references(google_account:[email_account:[:bot_server]])
        gaas = []
        google_account_activities.each do |gaa|
          gaa.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |yv|
              gaas << gaa if yv.call_to_action_overlay.present? && yv.call_to_action_overlay.acceptable_for_adding?
            end
          end
        end
        gaas = gaas.uniq
      elsif params[:potential_recovered_accounts]
        GoogleAccountActivity.potential_recovered_accounts(params[:last_days])
      else
        GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
        .where("google_account_activities.linked = false AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.bot_server_id = ?", bot_server.id)
        .order("google_account_activities.updated_at desc").references(google_account:[email_account:[:bot_server]])
      end
    respond_to do |format|
      format.html
      format.json {
        json_text = []
        if params[:recovery_attempt] == true.to_s || params[:potential_recovered_accounts] == true.to_s || params[:recovery_answers_checker] == true.to_s
          @google_account_activities.each do |gaa|
            json_object = {}
            json_object[:id] = gaa.id
            json_object[:email_account_id] = gaa.google_account.email_account.id
            json_object[:email] = gaa.google_account.email_account.email
            json_object[:password] = gaa.google_account.email_account.password
            json_object[:ip] = gaa.google_account.email_account.ip_address.try(:address)
            json_object[:recovery_email] = gaa.google_account.email_account.recovery_email
            json_object[:gender] = gaa.google_account.email_account.gender.try(:value) ? true : false
            json_object[:birth_date] = gaa.google_account.email_account.birth_date
            json_object[:first_name] = gaa.google_account.email_account.firstname
            json_object[:last_name] = gaa.google_account.email_account.lastname
            json_object[:recovery_attempts_count] = gaa.recovery_attempt.size
            json_object[:recovery_email_password] = gaa.google_account.email_account.recovery_email_password
            json_text << json_object
          end
        else
          @google_account_activities.each do |gaa|
            json_object = {}
            json_object[:id] = gaa.id
            json_object[:email_account_id] = gaa.google_account.email_account.id
            json_object[:email] = gaa.google_account.email_account.email
            json_object[:password] = gaa.google_account.email_account.password
            json_object[:ip] = gaa.google_account.email_account.ip_address.try(:address)
            json_text << json_object
          end
        end
        render :json => json_text.to_json
      }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json{
        client = @google_account_activity.google_account.email_account.client
        now = Time.now.in_time_zone('Eastern Time (US & Canada)')
        if !@google_account_activity.linked
          @google_account_activity.linked = true
          @google_account_activity.save
        end
        bot_server = @google_account_activity.google_account.email_account.bot_server
        json_text = {}
        json_text =  JSON.parse(@google_account_activity.to_json)
        json_text.delete_if{ |k,v| k.include? "_start" }
        %w(last_success_sign_in recovery_attempt recovery_attempt_crash recovery_answer
          recovery_answer_date activity_start activity_end activity_end_crash
          verification_code_success_attempt last_recovery_email_inbox_mail_date recovery_success_date today_online_time total_online_time start_online_at).each do |field|
          json_text.delete(field)
        end
        json_text["watching_videos_all_amount"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_ALL_AMOUNT").to_i
        json_text["watching_videos_minimum"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_MINIMUM").to_i
        json_text["watching_videos_maximum"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_MAXIMUM").to_i
        json_text["watching_videos_phrase"] = @google_account_activity.watching_video_categories.empty? ?
          '' : @google_account_activity.watching_video_categories.pluck(:phrases).join(",").split(",").shuffle.first
        json_text["email_account_id"] = @google_account_activity.google_account.email_account.id

        if @google_account_activity.google_account.email_account.is_active
          all_videos_privacy = ''
          create_youtube_business_channel = ''
          fill_youtube_business_channel = ''
          verify_youtube_business_channel = ''
          youtube_website_associate = ''
          assign_recovery_phone = ''
          youtube_video_upload = ''
          youtube_video_card_add = ''
          youtube_video_info = ''
          adwords_campaign_add = ''
          adwords_campaign_group_add = ''
          call_to_action_overlay_add = ''
          youtube_video_delete = ''
          google_plus_video_add = ''
          youtube_video_status = ''
          youtube_video_search_rank = ''
          recovery_email_sync = ''
          recovery_email = ''
          youtube_channel_recovery = ''
          security_checkup_enabled = ''

          @google_account_activity.google_account.youtube_channels.each do |yc|
            if yc.acceptable_for_recovery?
              youtube_channel_recovery = nil
            end
            unless yc.blocked
              if yc.acceptable_for_all_videos_privacy?
                all_videos_privacy = nil
              elsif yc.acceptable_for_creation?
                create_youtube_business_channel = nil
                fill_youtube_business_channel = nil
                verify_youtube_business_channel = nil
              elsif yc.acceptable_for_filling?
                fill_youtube_business_channel = nil
                verify_youtube_business_channel = nil if !yc.is_verified_by_phone
              elsif yc.acceptable_for_verification?
                verify_youtube_business_channel = nil
              end
              if client.try(:is_active)
                yc.associated_websites.sort.each do |aw|
                  youtube_website_associate = nil if aw.acceptable_for_adding?
                end
              end
            end
          end

          @google_account_activity.google_account.youtube_channels.each do |yc|
            unless yc.blocked
              yc.youtube_videos.each do |video|
                google_plus_video_add = nil if video.acceptable_for_posting_on_google_plus?
                youtube_video_upload = nil if video.acceptable_for_uploading?
                youtube_video_info = nil if video.acceptable_for_upload_changes?
                youtube_video_delete = nil if video.acceptable_for_deleting?
                if client.try(:is_active)
                  youtube_video_search_rank = nil if video.acceptable_for_search_rank?
                  youtube_video_status = nil if video.has_yt_statistics_errors?
                  video.youtube_video_cards.each do |yvc|
                    youtube_video_card_add = nil if yvc.acceptable_for_adding?
                  end
                  call_to_action_overlay_add = nil if video.call_to_action_overlay.present? && video.call_to_action_overlay.acceptable_for_adding?
                end
              end
            end
          end

          if client.try(:is_active)
            @google_account_activity.google_account.adwords_campaigns.each do |ac|
              if ac.acceptable_for_adding?
                adwords_campaign_add = nil
                adwords_campaign_group_add = nil
                call_to_action_overlay_add = nil
              end
              ac.adwords_campaign_groups.each do |acg|
                if acg.acceptable_for_adding?
                  adwords_campaign_group_add = nil
                  call_to_action_overlay_add = nil
                end
              end
            end
          end

          if bot_server.try(:recovery_phone_assign_enabled) && @google_account_activity.google_account.email_account.recovery_phone_assigned == false && @google_account_activity.google_account.email_account.recovery_phone_id.present?
            assign_recovery_phone = nil
          end

          if bot_server.try(:recovery_email_sync_enabled) && @google_account_activity.acceptable_for_recovery_email_sync?
            recovery_email_sync = nil
          end

          recovery_email = @google_account_activity.recovery_email.present? ? '' : nil

          if !assign_recovery_phone.nil? && @google_account_activity.google_account.email_account.recovery_phone_id.nil? && @google_account_activity.google_account.error_type.try(:value) == GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"] && Setting.get_value_by_name("GoogleAccountActivity::TRY_TO_RECOVER_WITH_DID_ENABLED") == true.to_s
            next_available_did = VoipmsService.next_available_did
            if next_available_did.present?
              @google_account_activity.google_account.email_account.assign_recovery_phone(next_available_did)
              assign_recovery_phone = nil
            end
          end

          if bot_server.present?
            youtube_video_status = '' unless bot_server.youtube_video_status
            create_youtube_business_channel = '' unless bot_server.create_youtube_business_channel
            fill_youtube_business_channel = '' unless bot_server.fill_youtube_business_channel
            verify_youtube_business_channel = '' unless bot_server.verify_youtube_business_channel
            youtube_website_associate = '' unless bot_server.youtube_website_associate
            assign_recovery_phone = '' unless bot_server.recovery_phone_assign_enabled
            youtube_video_upload = '' unless bot_server.youtube_video_upload
            youtube_video_card_add = '' unless bot_server.youtube_video_card_add
            youtube_video_info = '' unless bot_server.youtube_video_info
            adwords_campaign_add = '' unless bot_server.adwords_campaign_add
            adwords_campaign_group_add = '' unless bot_server.adwords_campaign_group_add
            call_to_action_overlay_add = '' unless bot_server.call_to_action_overlay_add
            youtube_video_delete = '' unless bot_server.youtube_video_delete
            google_plus_video_add = '' unless bot_server.google_plus_video_add
            youtube_video_search_rank = '' unless bot_server.youtube_video_search_rank
            youtube_channel_recovery = '' unless bot_server.youtube_channel_recovery
            security_checkup_enabled = '' unless bot_server.security_checkup_enabled
          end

          if youtube_channel_recovery.nil? || recovery_email.nil? || recovery_email_sync.nil? || all_videos_privacy.nil? || create_youtube_business_channel.nil? || verify_youtube_business_channel.nil? || assign_recovery_phone.nil? || fill_youtube_business_channel.nil?
            json_text.each {|key, value| json_text[key] = '' }
            json_text[:id] = @google_account_activity.id
            json_text[:email_account_id] = @google_account_activity.google_account.email_account.id
            json_text[:google_account_id] = @google_account_activity.google_account_id
            json_text[:recovery_email] = recovery_email
            json_text[:recovery_email_sync] = recovery_email_sync
            json_text[:youtube_channel_recovery] = youtube_channel_recovery
            json_text[:assign_recovery_phone] = assign_recovery_phone
            json_text[:all_videos_privacy] = all_videos_privacy
            json_text[:youtube_business_channel] = create_youtube_business_channel
            json_text[:verify_youtube_business_channel] = verify_youtube_business_channel
            json_text[:youtube_website_associate] = bot_server.present? && bot_server.youtube_website_associate ? nil : ''
            json_text[:fill_youtube_business_channel] = fill_youtube_business_channel
            json_text[:youtube_video_upload] = nil if bot_server.present? && bot_server.youtube_video_upload
            json_text[:linked] = @google_account_activity.linked
            json_text[:check_status] = nil
          elsif youtube_video_delete.nil? || youtube_video_info.nil? || youtube_video_upload.nil? || youtube_website_associate.nil? || youtube_video_card_add.nil? || adwords_campaign_add.nil? || adwords_campaign_group_add.nil? || call_to_action_overlay_add.nil? || google_plus_video_add.nil? || youtube_video_status.nil? || youtube_video_search_rank.nil?
            json_text.each {|key, value| json_text[key] = '' }
            json_text[:youtube_video_status] = bot_server.youtube_video_status ? nil : ''
            json_text[:youtube_video_delete] = bot_server.youtube_video_delete ? nil : ''
            json_text[:youtube_video_info] = bot_server.youtube_video_info ? nil : ''
            json_text[:youtube_website_associate] = bot_server.youtube_website_associate ? nil : ''
            json_text[:youtube_video_upload] = bot_server.youtube_video_upload ? nil : ''
            json_text[:youtube_video_card_add] = bot_server.youtube_video_card_add ? nil : ''
            json_text[:adwords_campaign_add] = bot_server.adwords_campaign_add ? nil : ''
            json_text[:adwords_campaign_group_add] = bot_server.adwords_campaign_group_add ? nil : ''
            json_text[:call_to_action_overlay_add] = bot_server.call_to_action_overlay_add ? nil : ''
            json_text[:google_plus_video_add] = bot_server.google_plus_video_add ? nil : ''
            json_text[:youtube_video_search_rank] = youtube_video_search_rank.nil? && !youtube_video_info.nil? && !youtube_video_upload.nil? ? nil : ''
          else
            if bot_server.present? && bot_server.only_priority_tasks
              json_text = {}
            else
              # Change some fields to empty but not null for Victor bot
              json_text[:youtube_video_status] = youtube_video_status
              json_text[:assign_recovery_phone] = assign_recovery_phone
              json_text[:youtube_business_channel] = create_youtube_business_channel
              json_text[:verify_youtube_business_channel] = verify_youtube_business_channel
              json_text[:fill_youtube_business_channel] = fill_youtube_business_channel
              json_text[:youtube_video_upload] = youtube_video_upload
              json_text[:youtube_video_card_add] = youtube_video_card_add
              json_text[:adwords_campaign_add] = adwords_campaign_add
              json_text[:adwords_campaign_group_add] = adwords_campaign_group_add
              json_text[:call_to_action_overlay_add] = call_to_action_overlay_add
              json_text[:youtube_personal_channel] = if @google_account_activity.youtube_personal_channel.empty? && @google_account_activity.created_at > (now - (7..10).to_a.sample.days)
                ''
              elsif @google_account_activity.youtube_personal_channel.present?
                @google_account_activity.youtube_personal_channel.last
              else
                nil
              end
              json_text[:check_status] = nil
              GoogleAccountActivity::DAYLY_FIELDS.each do |col|
                json_text[col] = nil
              end
              GoogleAccountActivity::WEEKLY_FIELDS.each do |col|
                json_text[col] = if @google_account_activity[col].empty? && (@google_account_activity.created_at > (now - 7.days))
                  ''
                elsif @google_account_activity[col].empty? || (@google_account_activity[col].present? && (@google_account_activity[col].last < (now - 7.days)))
                  nil
                else
                  @google_account_activity[col].last
                end
              end
              GoogleAccountActivity::MONTHLY_FIELDS.each do |col|
                json_text[col] = if @google_account_activity[col].empty? && (@google_account_activity.created_at > (now - 1.month))
                  ''
                elsif @google_account_activity[col].empty? || (@google_account_activity[col].present? && (@google_account_activity[col].last < (now - 1.month)))
                  nil
                else
                  @google_account_activity[col].last
                end
              end
              GoogleAccountActivity::THREE_MONTHS_FIELDS.each do |col|
                json_text[col] = if @google_account_activity[col].empty? && (@google_account_activity.created_at > (now - 3.months))
                  ''
                elsif @google_account_activity[col].empty? || (@google_account_activity[col].present? && (@google_account_activity[col].last < (now - 3.months)))
                  nil
                else
                  @google_account_activity[col].last
                end
              end
              GoogleAccountActivity::SIX_MONTHS_FIELDS.each do |col|
                json_text[col] = if @google_account_activity[col].empty? && (@google_account_activity.created_at > (now - 6.months))
                  ''
                elsif @google_account_activity[col].empty? || (@google_account_activity[col].present? && (@google_account_activity[col].last < (now - 6.months)))
                  nil
                else
                  @google_account_activity[col].last
                end
              end
              GoogleAccountActivity::UNUSED_FIELDS.each do |col|
                json_text[col] = ''
              end
              one_time_action_fields_percentage = 90
              GoogleAccountActivity::ONE_TIME_ACTION_FIELDS.sample(one_time_action_fields_percentage * GoogleAccountActivity::ONE_TIME_ACTION_FIELDS.size / 100).each do |col|
                json_text[col] = '' if @google_account_activity[col].empty?
              end
              json_text['recovery_email'] = @google_account_activity.recovery_email.present? ? '' : nil
              # json_text['alternate_email'] = if @google_account_activity.recovery_email.present? && !@google_account_activity.alternate_email.present?
              #   alternate_email_attempts_from_ip = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
              #   .where("email_accounts.is_active = true AND email_accounts.deleted IS NOT TRUE
              #     AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value} AND email_accounts.ip_address_id = ? AND google_account_activities.alternate_email[array_length(google_account_activities.alternate_email, 1)] > (current_timestamp - interval '1 day')", @google_account_activity.google_account.email_account.ip_address_id).references(google_account:[email_account:[:bot_server]]).size
              #   if alternate_email_attempts_from_ip <= Setting.get_value_by_name("GoogleAccountActivity::ADD_ALTERNATE_EMAIL_DAILY_PER_IP_LIMIT").to_i
              #     [true, false].shuffle.first ? nil : ''
              #   else
              #     ''
              #   end
              # else
              #   ''
              # end
              json_text['alternate_email'] = ''
              json_text['security_checkup'] = '' if bot_server.present? && !bot_server.security_checkup_enabled || [true, false].shuffle.first
              json_text["watching_videos"] = '' if Setting.get_value_by_name("GoogleAccountActivity::DO_WATCH_VIDEOS") == false.to_s
              json_text["search"] = '' if Setting.get_value_by_name("GoogleAccountActivity::DO_SEARCH") == false.to_s
              phone_number = @google_account_activity.google_account.email_account.recovery_phone
              json_text["recovery_phone_number"] = phone_number.present? ? phone_number.value : ""
              json_text["facebook_create_account"] = if Setting.get_value_by_name("GoogleAccountActivity::FACEBOOK_ACCOUNTS_CREATION_ENABLED") == 'true' && @google_account_activity.google_account.facebook_account.nil?
                nil
              else
                ""
              end
              json_text["google_plus_create_account"] = if Setting.get_value_by_name("GoogleAccountActivity::GOOGLE_PLUS_ACCOUNTS_CREATION_ENABLED") == 'true' && SocialAccount.joins("LEFT JOIN google_plus_accounts ON social_accounts.social_item_id = google_plus_accounts.id AND social_accounts.social_item_type = 'GooglePlusAccount'").where("google_plus_accounts.google_account_id = ? AND social_accounts.account_type = ?", @google_account_activity.google_account_id, SocialAccount.account_type.find_value(:personal).value).size == 0
                nil
              else
                ""
              end
            end
          end
        else
          json_text = json_text.each {|key, value| json_text[key] = '' if value.nil? || value.is_a?(Array)}
        end
        json_text.delete_if {|key, value| value != nil}
        render :json => json_text.to_json
      }
    end
  end

  # PATCH/PUT /google_account_activities/1
  # PATCH/PUT /google_account_activities/1.json
  def update
    respond_to do |format|
      if @google_account_activity.update(google_account_activity_params)
        format.html { redirect_to google_account_activities_path }
        response = {status: 200}
        format.json { render json: response, status: response[:status] }
      else
        format.html { render action: 'edit' }
        format.json { render json: @google_account_activity.errors, status: :unprocessable_entity }
      end
    end
  end

  def touch
    email_account = @google_account_activity.google_account.email_account
    google_account = @google_account_activity.google_account
    ip_path = email_account.bot_server.try(:path) || Setting.get_value_by_name("EmailAccount::BOT_URL")
    only_update = false
    now = Time.now
    if params[:is_active].present? || params[:deleted].present? || params[:error_type].present? || params[:last_recovery_email_inbox_mail_date].present? || params[:assign_recovery_phone].present? ||
    params[:adwords_id].present? || params[:had_recovery_email].present? || params[:youtube_data_api_key].present? || params[:recovery_email_sync].present? || params[:recovery_email].present? || params[:recovery_email_password].present? || params[:firstname].present? || params[:lastname].present? || params[:gender].present? || params[:birth_date].present?
      if params[:recovery_email].present?
        email_account.recovery_email = params[:recovery_email].strip
      end
      if params[:recovery_email_password].present?
        email_account.recovery_email_password = params[:recovery_email_password].strip
      end
      if params[:firstname].present?
        email_account.firstname = params[:firstname].strip
      end
      if params[:lastname].present?
        email_account.lastname = params[:lastname].strip
      end
      if params[:gender].present?
        email_account.gender = params[:gender].to_s.strip.downcase == "true"
      end
      if params[:birth_date].present?
        email_account.birth_date = DateTime.parse(params[:birth_date])
      end
      if params[:is_active].present?
        if params[:is_active] == "true"
          email_account.is_active = true
          email_account.deleted = false
          if params[:field].present? && params[:field] == "recovery_success_date"
            google_account.error_type = GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"]
            google_account.save
          end
        elsif params[:is_active] == "false"
          email_account.is_active = false
        end
      end
      if params[:deleted].present?
        email_account.is_active = false if params[:deleted] == "true"
        email_account.deleted = params[:deleted] == "false" ? false : true
      end
      if params[:error_type].present?
        error_type_value = params[:error_type].try(:to_i)
        error_type_value = nil if error_type_value.present? && error_type_value == 0
        email_account.email_item.error_type = error_type_value
        if error_type_value == GoogleAccount.error_type.find_value("sorry, google doesn't recognize that email").value
          email_account.is_active = false
          email_account.deleted = true
        end
      end
      if params[:last_recovery_email_inbox_mail_date].present?
        @google_account_activity.last_recovery_email_inbox_mail_date = params[:last_recovery_email_inbox_mail_date]
        @google_account_activity.save
      end
      email_account.password = params[:password] if params[:password].present?
      if params[:assign_recovery_phone] == "true"
        email_account.recovery_phone_assigned = true
        email_account.recovery_phone_assigned_at = now
        email_account.recovery_phone.last_assigned_at = now
        email_account.recovery_phone.save
        @google_account_activity.touch("assign_recovery_phone", now)
      end
      if params[:adwords_id].present?
        google_account.adwords_id = params[:adwords_id]
        google_account.save
      end
      if params[:had_recovery_email].present?
        email_account.had_recovery_email = params[:had_recovery_email] == "true" ? true : false
      end
      if params[:youtube_data_api_key].present?
        google_account.youtube_data_api_key = params[:youtube_data_api_key].strip
        google_account.save
      end
      if params[:recovery_email_sync].present?
        email_account.recovery_email_sync = params[:recovery_email_sync] == "true" ? true : false
      end
      email_account.save
      only_update = true
    end

    field = params[:field]
    response = if field.present? && (GoogleAccountActivity.column_names.include? field)
      if params[:field] == "youtube_personal_channel" && @google_account_activity.google_account.youtube_channels.size == 0
        YoutubeChannel.create(category: YoutubeChannel.category.find_value("Other"),
          youtube_channel_name: email_account.full_name,
          channel_type: YoutubeChannel.channel_type.find_value(:personal),
          google_account: @google_account_activity.google_account,
          is_active: true, linked: true)
      end
      if !params[:no_touch].present?
        @google_account_activity.touch(field, now)
        @google_account_activity.update_attribute("updated_at", now - 2.days) if params[:is_active] == "true" && params[:field] == "recovery_success_date"
      end
      if !field.include? "_start"
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::OTHER_SCREENSHOT_PATH"))
      end
      if field == "check_status"
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::SIGN_IN_SCREENSHOT_PATH"))
      end
      if field == "activity_start" && !@google_account_activity.start_online_at.present? && email_account.is_active
        @google_account_activity.start_online_at = now
        @google_account_activity.save
      end
      if field == "activity_end"
        @google_account_activity.add_online_time if email_account.is_active
        email_account.delay(queue: DelayedJobQueue::SAVE_PROFILE_CACHE, priority: 1, run_at: 1.minutes.from_now).save_profile_cache(ip_path)
        if params[:user_agent].present?
          user_agent = params[:user_agent].strip
          begin
            FileUtils.mkdir_p "/tmp/broadcaster/user_agents"
            path = "/tmp/broadcaster/user_agents/#{email_account.id}.txt"
            f = File.open(path, "w")
            f.write(user_agent)
            f.close
            email_account.user_agent = open(f)
            email_account.save
          end
        end
        EmailService.delay_retrieve_emails(email_account.id)
      end
      if field == "activity_end_crash"
        @google_account_activity.add_online_time if email_account.is_active
        email_account.delay(queue: DelayedJobQueue::SAVE_PROFILE_CACHE, priority: 1, run_at: 1.minutes.from_now).save_profile_cache(ip_path)
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::OTHER_SCREENSHOT_PATH"))
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_PHONE_ASSIGN_SCREENSHOT_PATH"))
        if params[:user_agent].present?
          user_agent = params[:user_agent].strip
          begin
            FileUtils.mkdir_p "/tmp/broadcaster/user_agents"
            path = "/tmp/broadcaster/user_agents/#{email_account.id}.txt"
            f = File.open(path, "w")
            f.write(user_agent)
            f.close
            email_account.user_agent = open(f)
            email_account.save
          end
        end
        EmailService.delay_retrieve_emails(email_account.id)
      end
      if field == "recovery_attempt"
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_ATTEMPT_SCREENSHOT_PATH"))
        @google_account_activity.recovery_responses << RecoveryResponse.create(response: params[:response_text]) if params[:response_text].present?
      end
      if field == "youtube_channel_recovery"
        email_account.delay(queue: DelayedJobQueue::SAVE_SCREENSHOT, priority: 2).save_screenshot(Setting.get_value_by_name("EmailAccount::RECOVERY_ATTEMPT_SCREENSHOT_PATH"))
        channel_ids = @google_account_activity.google_account.youtube_channels.map(&:id)
        RecoveryResponse.create(response: params[:response_text], resource_id: params[:channel_id].to_i, resource_type: "YoutubeChannel") if params[:response_text].present? && params[:channel_id].present? && channel_ids.include?(params[:channel_id].to_i)
      end
      if %w(youtube_video_upload youtube_video_info fill_youtube_business_channel).include?(field)
        youtube_channels = YoutubeChannel.by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).by_is_active("true").by_blocked("false").where("google_account_id = ?", google_account.id)
        if Setting.get_value_by_name("YoutubeService::YOUTUBE_STATISTICS_ENABLED") == "true"
          youtube_channels.each do |youtube_channel|
            YoutubeService.delay(queue: DelayedJobQueue::GRAB_YOUTUBE_STATISTICS, priority: 0, run_at: 1.hour.from_now).grab_channel_statistics(youtube_channel, nil, nil, nil, true)
          end
        end
      end
      if field == "alternate_email"
        google_account.alternate_email = email_account.recovery_email
        google_account.save
      end
      if %w(youtube_business_channel verify_youtube_business_channel fill_youtube_business_channel).include?(field)
        youtube_channel = YoutubeChannel.by_channel_type(YoutubeChannel.channel_type.find_value(:business).value.to_s).where("google_account_id = ?", google_account.id).order(updated_at: :desc).first
        if @google_account_activity["#{field}_start"].present? && @google_account_activity["#{field}"].present? && @google_account_activity["#{field}_start"].last < @google_account_activity["#{field}"].last
          time = Time.at(@google_account_activity["#{field}"].last - @google_account_activity["#{field}_start"].last).utc
          posting_time = youtube_channel.posting_time.to_i
          posting_time += time.hour*3600 + time.min*60 + time.sec if time.hour == 0 && time.min < 30
          youtube_channel.update_attribute("posting_time", posting_time)
        end
      end
      {status: 200}
    else
      if only_update
        {status: 200}
      else
        {status: 500}
      end
    end
    render json: response, status: response[:status]
  end

  def fetch_field
    google_account = @google_account_activity.google_account
    email_account = @google_account_activity.google_account.email_account
    name = params[:name]
    response = if name.present?
      result = nil

      if name == "recovery_phone"
        if email_account.is_active && email_account.recovery_phone_id.nil? && google_account.error_type.try(:value) == GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"] && Setting.get_value_by_name("GoogleAccountActivity::TRY_TO_RECOVER_WITH_DID_ENABLED") == true.to_s
          next_available_did = VoipmsService.next_available_did
          email_account.assign_recovery_phone(next_available_did) if next_available_did.present?
        end
        result = email_account.recovery_phone.try(:value)
      elsif name == "ip" || name == "ip_address"
        result = email_account.ip_address.try(:address)
      else
        result = email_account[name]
        result = google_account[name] if result.nil?
      end
      if name == "phone_number"
        result = email_account.recovery_phone.present? ? email_account.recovery_phone.value : email_account.recovery_phone_number
      end
      result = "" if result.nil?
      result
    else
      {status: 500}
    end
    render json: response
  end

  def rerun_youtube_business_channels_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(:email_account).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.recovery_phone_assigned = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND (youtube_channels.is_verified_by_phone=FALSE OR youtube_channels.filled = FALSE)", YoutubeChannel.channel_type.find_value(:business).value).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?) AND bot_servers.id = ?", google_accounts_ids, bot_server.id)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.youtube_channels.each do |yc|
        gaas << gaa if yc.channel_type == "business" && (yc.acceptable_for_creation? || yc.acceptable_for_verification? || yc.acceptable_for_filling?)
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def rerun_youtube_videos_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?)", google_accounts_ids)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.youtube_channels.each do |yc|
        yc.youtube_videos.each do |yv|
          gaas << gaa if yc.channel_type == "business" && yv.acceptable_for_uploading?
        end
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def rerun_youtube_videos_info_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    gaas = GoogleAccountActivity.joins("LEFT JOIN google_accounts ON google_accounts.id = google_account_activities.google_account_id
      LEFT JOIN email_accounts ON email_accounts.email_item_id = google_accounts.id
      LEFT JOIN ip_addresses ON email_accounts.ip_address_id = ip_addresses.id
      LEFT JOIN youtube_channels ON youtube_channels.google_account_id = google_accounts.id
      LEFT JOIN youtube_videos ON youtube_videos.youtube_channel_id = youtube_channels.id
      LEFT JOIN bot_servers ON bot_servers.id = email_accounts.bot_server_id
      and email_accounts.email_item_type = 'GoogleAccount'")
      .where("email_accounts.is_active = true AND youtube_videos.ready = true AND youtube_videos.linked = false AND bot_servers.id = ?", bot_server.id)
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts for rerun_youtube_video_info_activity on #{bot_server.name};\n"
    render json: response
  end

  def rerun_youtube_video_cards_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?)", google_accounts_ids)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.youtube_channels.each do |yc|
        yc.youtube_videos.each do |yv|
          yv.youtube_video_cards.each do |yvc|
            gaas << gaa if yvc.acceptable_for_adding?
          end
        end
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def rerun_adwords_campaigns_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?)", google_accounts_ids)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.adwords_campaigns.each do |ac|
        gaas << gaa if ac.acceptable_for_adding?
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def rerun_adwords_campaign_groups_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?)", google_accounts_ids)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.adwords_campaigns.each do |ac|
        ac.adwords_campaign_groups.each do |acg|
          gaas << gaa if acg.acceptable_for_adding?
        end
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def rerun_call_to_action_overlays_activity
    response = ""
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    google_accounts_ids = GoogleAccount.includes(email_account:[:bot_server]).joins(:youtube_channels)
    .where("email_accounts.client_id IS NOT NULL AND email_accounts.actual IS TRUE AND email_accounts.account_type = #{EmailAccount.account_type.find_value(:operational).value}
      AND email_accounts.is_active = TRUE AND email_accounts.deleted IS NOT TRUE
      AND youtube_channels.channel_type = ? AND youtube_channels.is_verified_by_phone = TRUE AND bot_servers.id = ?", YoutubeChannel.channel_type.find_value(:business).value, bot_server.id).pluck(:id)

    google_account_activities = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]])
    .where("google_account_id in (?)", google_accounts_ids)
    .references(google_account:[email_account:[:bot_server]])
    gaas = []
    google_account_activities.each do |gaa|
      gaa.google_account.youtube_channels.each do |yc|
        yc.youtube_videos.each do |yv|
          gaas << gaa if yv.call_to_action_overlay.present? && yv.call_to_action_overlay.acceptable_for_adding?
        end
      end
    end
    gaas = gaas.uniq

    if gaas.size > 0
      GoogleAccountActivity.where("id in (?)", gaas.map(&:id)).update_all({linked: false, updated_at: Time.now}) if gaas.present?
      start_job_response = Utils.http_get("#{bot_server.path}/add_activity_count.php", {count: gaas.size}, 3, 10).try(:body).to_s
    end
    response += "Successfully executed #{gaas.size} accounts on #{bot_server.name};\n"
    render json: response
  end

  def recovery_attempt_answer
    response = if params[:got].present?
      now = Time.now
      bot_server = @google_account_activity.google_account.email_account.bot_server
      date_from = bot_server.recovery_bot_running_status_updated_at.getgm
      last_answer_date = @google_account_activity.recovery_answer_date.last.try(:getgm)
      if last_answer_date.present? && date_from.present? && last_answer_date > date_from
        if ![GoogleAccountActivity::RECOVERY_ANSWERS["No answer"], GoogleAccountActivity::RECOVERY_ANSWERS["Authentification failed"]].include?(params[:got].to_i) || @google_account_activity.recovery_answer.last == GoogleAccountActivity::RECOVERY_ANSWERS["Authentification failed"]
          @google_account_activity.add_recovery_answer(params[:got].to_i)
          @google_account_activity.touch("recovery_answer_date", now)
        end
      else
        @google_account_activity.add_recovery_answer(params[:got].to_i)
        @google_account_activity.touch("recovery_answer_date", now)
      end
      if params[:got].to_i == GoogleAccountActivity::RECOVERY_ANSWERS["Positive answer"]
        google_account = @google_account_activity.google_account
        google_account.error_type = GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"]
        google_account.save
      end
      {status: 200}
    else
      {status: 500}
    end
    render json: response, status: response[:status]
  end

  def run_daily_activity
    bot_server = BotServer.find(params[:bot_server_id])
    GoogleAccountActivity.fields_updater([bot_server].compact)
    response = "Daily activity was successfully executed"
    render json: response
  end

  def clear_daily_activity_queue
    bot_server = BotServer.find_by_id(params[:bot_server_id])
    gaa_ids = GoogleAccountActivity.includes(google_account:[email_account:[:bot_server]]).where("bot_servers.id = ? AND google_account_activities.linked IS NOT TRUE", bot_server.id).pluck(:id)
    GoogleAccountActivity.where("id in (?)", gaa_ids).update_all({linked: true, updated_at: Time.now - 2.days}) if gaa_ids.present?
    response = "Daily activity queue was successfully cleared"
    render json: response
  end

  def recovery_attempt_response
    respond_to do |format|
      format.json {
        begin
          EmailService.retrieve_recovery_inbox_emails(@google_account_activity.google_account.email_account)
        rescue
          ActiveRecord::Base.logger.info "EmailService.retrieve_recovery_inbox_emails FAILED at: #{Time.now}"
        end
        response_text = if params[:type] == 'youtube'
          youtube_channel = nil
          @google_account_activity.google_account.youtube_channels.each {|yc| youtube_channel = yc if yc.channel_type.business? && yc.youtube_channel_id.present? && yc.blocked}
          {id: youtube_channel.try(:id), youtube_channel_id: youtube_channel.try(:youtube_channel_id), channel_name: youtube_channel.try(:youtube_channel_name), response_text: RecoveryResponse.generate_response_text('youtube', @google_account_activity.youtube_channel_recovery.size, RecoveryResponse::YOUTUBE_RESPONSE_LIMIT, RecoveryInboxEmail.where("email_type in (?) AND email_account_id = ? AND date > ?", RecoveryResponse::YOUTUBE_POLICY_NAMES_BY_EMAIL_TYPE.keys.flatten, @google_account_activity.google_account.email_account.id, Time.now - 30.days).order(date: :desc).first)}
        else
          RecoveryResponse.generate_response_text('gmail', @google_account_activity.recovery_attempt.size, RecoveryResponse::GMAIL_RESPONSE_LIMIT, RecoveryInboxEmail.where("email_type in (?) AND email_account_id = ? AND date > ?", RecoveryResponse::GOOGLE_POLICY_NAMES_BY_EMAIL_TYPE.keys.flatten, @google_account_activity.google_account.email_account.id, Time.now - 30.days).order(date: :desc).first)
        end
        render :json => response_text
      }
    end
  end

  def bot_action
    respond_to do |format|
      format.json {
        bot_server = @google_account_activity.google_account.email_account.bot_server
        json_text = {}
        url =  if request.domain == "localhost"
            request.protocol + request.host_with_port
          else
            request.protocol + request.host
          end
        if params[:field] == "watching_videos"
          json_text["watching_videos_all_amount"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_ALL_AMOUNT").to_i
          json_text["watching_videos_minimum"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_MINIMUM").to_i
          json_text["watching_videos_maximum"] = Setting.get_value_by_name("GoogleAccountActivity::WATCHING_VIDEOS_MAXIMUM").to_i
          json_text["watching_videos_phrase"] = @google_account_activity.watching_video_categories.empty? ?
            '' : @google_account_activity.watching_video_categories.pluck(:phrases).join(",").split(",").shuffle.first
        end
        if params[:field] == "search"
          json_text["phrase"] = WatchingVideoCategory.order("random()").first.phrases.split(",").shuffle.first
          json_text["search_site_presence_minimum"] = Setting.get_value_by_name("GoogleAccountActivity::SEARCH_SITE_PRESENCE_MINIMUM").to_i
          json_text["search_site_presence_maximum"] = Setting.get_value_by_name("GoogleAccountActivity::SEARCH_SITE_PRESENCE_MAXIMUM").to_i
          json_text["search_total_time"] = if @google_account_activity.google_account.error_type.try(:value) == GoogleAccount::ERROR_TYPES["provide a phone number, we'll send a verification code"]
             Setting.get_value_by_name("GoogleAccountActivity::SEARCH_TOTAL_TIME").to_i / 2
          else
            Setting.get_value_by_name("GoogleAccountActivity::SEARCH_TOTAL_TIME").to_i
          end
          json_text["search_sites_per_phrase_minimum"] = Setting.get_value_by_name("GoogleAccountActivity::SEARCH_SITES_PER_PHRASE_MINIMUM").to_i
          json_text["search_sites_per_phrase_maximum"] = Setting.get_value_by_name("GoogleAccountActivity::SEARCH_SITES_PER_PHRASE_MAXIMUM").to_i
          json_text["search_phrases_number"] = Setting.get_value_by_name("GoogleAccountActivity::SEARCH_PHRASES_NUMBER").to_i
        end
        if params[:field] == "verification_code_success_attempt"
          json_text = @google_account_activity.verification_code_success_attempt.size
        end
        if params[:field] == "last_recovery_email_inbox_mail_date"
          json_text = @google_account_activity.last_recovery_email_inbox_mail_date.present? ? @google_account_activity.last_recovery_email_inbox_mail_date : ''
        end
        if params[:field] == "all_videos_privacy"
          ybc = nil
          @google_account_activity.google_account.youtube_channels.each do |yc|
            ybc = yc if yc.acceptable_for_all_videos_privacy?
          end
          if ybc.present?
            json_text = ybc.json
            json_text[:all_videos_privacy] = ybc.all_videos_privacy
          end
        end
        if params[:field] == "youtube_business_channel"
          ybc = nil
          @google_account_activity.google_account.youtube_channels.each do |yc|
            ybc = yc if yc.acceptable_for_creation?
          end
          if ybc.present?
            json_text = ybc.json
            json_text[:phone_number] = if ybc.google_account.email_account.recovery_phone.present? && ybc.google_account.email_account.recovery_phone_assigned
              ybc.google_account.email_account.recovery_phone.value
            else
              ""
            end
            json_text[:channel_icon_url] = !ybc.channel_icon.blank? ? URI::escape(url + ybc.channel_icon.url(:original), '[]') : ''
            json_text[:channel_art_url] =  !ybc.channel_art.blank? ? URI::escape(url + ybc.channel_art.url(:original), '[]') : ''
          end
        end

        if params[:field] == "verify_youtube_business_channel"
          ybc = nil
          @google_account_activity.google_account.youtube_channels.each do |yc|
            ybc = yc if yc.acceptable_for_verification?
          end
          if ybc.present?
            json_text = ybc.json
            json_text[:phone_number] = if ybc.can_be_verified_by_own_number?
              ybc.google_account.email_account.recovery_phone.value
            else
              ""
            end
            json_text[:channel_icon_url] = !ybc.channel_icon.blank? ? URI::escape(url + ybc.channel_icon.url(:original), '[]') : ''
            json_text[:channel_art_url] =  !ybc.channel_art.blank? ? URI::escape(url + ybc.channel_art.url(:original), '[]') : ''
          end
        end

        if params[:field] == "fill_youtube_business_channel"
          ybc = nil
          @google_account_activity.google_account.youtube_channels.each do |yc|
            ybc = yc if yc.acceptable_for_filling?
          end
          if ybc.present?
            json_all = ybc.json
            json_text["phone_number"] = if ybc.can_be_verified_by_own_number?
              ybc.google_account.email_account.recovery_phone.value
            else
              ""
            end
            json_all["channel_icon_url"] = !ybc.channel_icon.blank? ? URI::escape(url + ybc.channel_icon.url(:original), '[]') : ''
            json_all["channel_art_url"] =  !ybc.channel_art.blank? ? URI::escape(url + ybc.channel_art.url(:original), '[]') : ''
            json_text = {}
            %w(id youtube_channel_id).each do |f|
              json_text[f] = json_all[f]
            end
            fields_to_update_array = ybc.fields_to_update.to_s.split(',').collect(&:strip).uniq
            if fields_to_update_array.include?("channel_icon")
              json_text["channel_icon_url"] = json_all["channel_icon_url"]
            end
            if fields_to_update_array.include?("channel_art")
              json_text["channel_art_url"] = json_all["channel_art_url"]
            end
            fields_to_update_array.each do |field|
              json_text[field] = json_all[field] unless %w(channel_art channel_icon).include?(field)
            end
          end
        end

        if params[:field] == "youtube_website_associate"
          json_text = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.associated_websites.each do |aw|
              json_text << aw.json if aw.acceptable_for_adding?
            end
          end
        end

        if params[:field] == "assign_recovery_phone"
          json_text[:phone_number] = @google_account_activity.google_account.email_account.recovery_phone.try(:value).to_s
        end

        if params[:field] == "youtube_video_delete"
          yv = nil
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              yv = video if video.acceptable_for_deleting?
            end
          end
          if yv.present?
            json_text = yv.json
          end
        end

        if params[:field] == "youtube_video_status"
          yvs = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              yvs << video if video.has_yt_statistics_errors?
            end
          end
          if yvs.present?
            json_text = []
            yvs.each do |yv|
              json = yv.json
              json["thumbnail_url"] = yv.thumbnail.present? ? URI::escape(url + yv.thumbnail.url(:original), '[]') : ""
              json["video_full_path"] = yv.blended_video.present? && yv.blended_video.file.present? ? URI::escape(url + yv.blended_video.file.url(:original), '[]') : ""
              json_text << json
            end
          end
        end

        if params[:field] == "youtube_video_upload"
          posting_limit = bot_server.present? ? (bot_server.minimum_videos_to_post..bot_server.maximum_videos_to_post).to_a.sample : 5
          yvs = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              yvs << video if video.acceptable_for_uploading?
              break if yvs.size == posting_limit
            end
          end
          if yvs.present?
            json_text = []
            yvs.each do |yv|
              json = yv.json
              json["thumbnail_url"] = yv.thumbnail.present? ? URI::escape(url + yv.thumbnail.url(:original), '[]') : ""
              json["video_full_path"] = yv.blended_video.present? && yv.blended_video.file.present? ? URI::escape(url + yv.blended_video.file.url(:original), '[]') : ""
              json_text << json
            end
          end
        end

        if params[:field] == "youtube_video_info"
          json_text = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |yv|
              if yv.acceptable_for_upload_changes?
                json = {}
                json_all = yv.json
                json_all["thumbnail_url"] = yv.thumbnail.present? ? URI::escape(url + yv.thumbnail.url(:original), '[]') : ""
                json_all["video_full_path"] = yv.blended_video.present? && yv.blended_video.file.present? ? URI::escape(url + yv.blended_video.file.url(:original), '[]') : ""
                json = {}
                %w(id youtube_channel_id youtube_video_id).each do |f|
                  json[f] = json_all[f]
                end
                fields_to_update_array = yv.fields_to_update.to_s.split(',').collect(&:strip).uniq
                if fields_to_update_array.include?("thumbnail")
                  json["thumbnail_url"] = json_all["thumbnail_url"]
                end
                if fields_to_update_array.include?("video")
                  json["video_full_path"] = json_all["video_full_path"]
                  json["video_file_name"] = json_all["video_file_name"]
                  json["video_relative_path"] = json_all["video_relative_path"]
                end
                if fields_to_update_array.include?("category")
                  json["category"] = json_all["category"]
                  json["category_name"] = json_all["category_name"]
                end
                fields_to_update_array.each do |field|
                  json[field] = json_all[field] unless %w(thumbnail video).include?(field)
                end
                json_text << json
              end
            end
          end
        end

        if params[:field] == "youtube_video_card_add"
          posting_limit = bot_server.present? ? (bot_server.minimum_cards_to_post..bot_server.maximum_cards_to_post).to_a.sample : 5
          cards_array = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              video.youtube_video_cards.sort.each do |yvc|
								yvc_json = yvc.json
                card_image_url = if yvc.card_image.present?
                  URI::escape(url + yvc.card_image.url(:original), '[]')
                else
                  !yc.channel_icon.blank? ? URI::escape(url + yc.channel_icon.url(:original), '[]') : ''
                end
								yvc_json['card_image_url'] = card_image_url
                cards_array << yvc_json if yvc.acceptable_for_adding?
                yvc_json['youtube_channel_id'] = yc.id
              end
              break if cards_array.size > posting_limit
            end
          end
          json_text = cards_array.take(posting_limit)
        end

        if params[:field] == "adwords_campaign_add"
          posting_limit = bot_server.present? ? (bot_server.minimum_adwords_campaigns_to_post..bot_server.maximum_adwords_campaigns_to_post).to_a.sample : 5
          adwords_campaigns_array = []
          @google_account_activity.google_account.adwords_campaigns.each do |ac|
            adwords_campaigns_array << ac.json if ac.acceptable_for_adding?
            break if adwords_campaigns_array.size == posting_limit
          end
          json_text = adwords_campaigns_array.take(posting_limit)
        end

        if params[:field] == "adwords_campaign_group_add"
          posting_limit = bot_server.present? ? (bot_server.minimum_adwords_campaign_groups_to_post..bot_server.maximum_adwords_campaign_groups_to_post).to_a.sample : 5
          adwords_campaign_groups_array = []
          @google_account_activity.google_account.adwords_campaigns.each do |ac|
            ac.adwords_campaign_groups.each do |acg|
              adwords_campaign_groups_array << acg.json if acg.acceptable_for_adding?
            end
            break if adwords_campaign_groups_array.size > posting_limit
          end
          json_text = adwords_campaign_groups_array.take(posting_limit)
        end

        if params[:field] == "call_to_action_overlay_add"
          posting_limit = bot_server.present? ? (bot_server.minimum_call_to_actions_to_post..bot_server.maximum_call_to_actions_to_post).to_a.sample : 5
          call_to_action_overlays_array = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              call_to_action_overlays_array << video.call_to_action_overlay.json if video.call_to_action_overlay.present? &&  video.call_to_action_overlay.acceptable_for_adding?
            end
            break if call_to_action_overlays_array.size > posting_limit
          end
          json_text = call_to_action_overlays_array.take(posting_limit)
        end

        if params[:field] == "google_plus_video_add"
          posting_limit = bot_server.present? ? (bot_server.minimum_videos_on_google_plus_to_post..bot_server.maximum_videos_on_google_plus_to_post).to_a.sample : 5
          yvs = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              yvs << video if video.acceptable_for_posting_on_google_plus?
            end
            break if yvs.size > posting_limit
          end
          if yvs.present?
            json_text = []
            yvs.each do |yv|
              json = yv.json
              json_text << json
            end
          end
          json_text = json_text.take(posting_limit)
        end

        if params[:field] == "facebook_create_account"
          json_text[:phone_number] = if @google_account_activity.google_account.email_account.recovery_phone.present? && @google_account_activity.google_account.email_account.recovery_phone_assigned && @google_account_activity.google_account.email_account.recovery_phone.facebook_accounts_assigned_size < Setting.get_value_by_name("FacebookAccount::FACEBOOK_ACCOUNTS_PER_PHONE_LIMIT").to_i && @google_account_activity.google_account.email_account.recovery_phone.facebook_usable
            @google_account_activity.google_account.email_account.recovery_phone.value
          else
            ""
          end
        end

        if params[:field] == "youtube_video_search_rank"
          yvs = []
          @google_account_activity.google_account.youtube_channels.each do |yc|
            yc.youtube_videos.each do |video|
              yvs << video if video.acceptable_for_search_rank?
            end
          end
          if yvs.present?
            rank_check_frequency_days = Setting.get_value_by_name("YoutubeVideoSearchRank::RANK_CHECK_FREQUENCY_DAYS").to_i
            json_text = []
            yvs.each do |yv|
              json = {"video_id" => yv.id, "youtube_video_id" => yv.youtube_video_id}
              json["search_phrases"] = []
              YoutubeVideoSearchRank::SEARCH_TYPES.keys.each do |search_type|
                yv.active_youtube_video_search_phrases.each do |sph|
                  if !YoutubeVideoSearchRank.where("youtube_video_search_phrase_id = ? AND created_at > ? AND search_type = ? AND current = true", sph.id, Time.now - rank_check_frequency_days.days, YoutubeVideoSearchRank.search_type.find_value(search_type).value).present? && ((yv.rotate_content_date || yv.publication_date) + Setting.get_value_by_name("YoutubeVideoSearchRank::RANK_CHECK_FIRST_TIME_DELAY_DAYS").to_i.day < Time.now)
                    phrase_json = {}
                    phrase_json["phrase_id"] = sph.id
                    phrase_json["phrase"] = sph.phrase
                    phrase_json["search_type"] = search_type
                    json["search_phrases"] << phrase_json
                  end
                end
              end
              json_text << json
            end
          end
        end

        render :json => json_text.to_json
      }
    end
  end

  def rerun_recovery_process_activity
    bot_server = BotServer.find(params[:bot_server_id])
    if params[:all].present? && params[:all] == "true"
      GoogleAccountActivity.start_recovery_attempt_process(bot_server, true)
    else
      GoogleAccountActivity.start_recovery_attempt_process(bot_server)
    end
    response = "Successfully executed recovery process"
    render json: response
  end

  def turn_recovery_attempt_activity
    # setting = Setting.find_by_name("GoogleAccountActivity::RECOVERY_BOT_RUNNING_STATUS")
    # now = Time.now.in_time_zone('Eastern Time (US & Canada)')
    response = if params[:running].present? && setting.present?
    #   if params[:running] == false.to_s
    #     if setting.value == true.to_s
    #       GoogleAccountActivity.delay(run_at: Setting.get_value_by_name("GoogleAccountActivity::RECOVERY_ATTEMPTS_RETRY_INTERVAL").to_i.minutes.from_now).start_recovery_attempt_process(nil)
    #     end
    #     setting.value = false.to_s
    #   end
    #   if params[:running] == true.to_s && (now.hour == 12 || now.hour == 0)
    #     setting.value = true.to_s
    #   end
    #   setting.save
    #   setting.touch
      {status: 200}
    else
      {status: 500}
    end
    render json: response, status: response[:status]
  end

  def phone_usage
    @google_account_activity = GoogleAccountActivity.find_by_id(params[:id])
    response = if params[:service].present?
      phone_usage = PhoneUsage.create_from_params(params, @google_account_activity)
      if phone_usage.phone.present? && phone_usage.error_type.try(:value) == PhoneUsage.error_type.find_value("google accepted provided phone, sms was not received").value
        phone = phone_usage.phone
        if PhoneUsage.where("phone_id = ? AND created_at > '2017-01-01 00:00:00' AND error_type = ?", phone.id, PhoneUsage.error_type.find_value("google accepted provided phone, sms was not received").value).size >= 3
          phone.usable = false
          phone.unusable_at = Time.now
          phone.save
        end
      end
      { status: 200 }
    else
      { status: 500 }
    end
    render json: response, status: response[:status]
  end

  def create_facebook_account
    account_type = SocialAccount::ACCOUNT_TYPES[:personal] unless params[:account_type].present?
    phone_number = params[:phone_number].try(:strip)
    phone = Phone.where(value: phone_number).first
    response = unless @google_account_activity.google_account.facebook_account.present?
      f = FacebookAccount.new(google_account: @google_account_activity.google_account, phone_number: phone_number, phone: phone)
      f.build_social_account(is_active:true, password: @google_account_activity.google_account.email_account.password, account_type: account_type)
      f.save ? "Successfully created" : "Something wrong"
    else
      "Already exists. Social Item ID: #{@google_account_activity.google_account.facebook_account.id}"
    end
    render json: response
  end

  def create_google_plus_account
    account_type = SocialAccount::ACCOUNT_TYPES[:personal] unless params[:account_type].present?
    google_plus_accounts_size = SocialAccount.joins("LEFT JOIN google_plus_accounts ON social_accounts.social_item_id = google_plus_accounts.id AND social_item_type = 'GooglePlusAccount'").where("google_plus_accounts.google_account_id = ? AND social_accounts.account_type = ?", @google_account_activity.google_account.id, account_type).size
    response = if google_plus_accounts_size == 0
      g_plus_account = GooglePlusAccount.new(google_account: @google_account_activity.google_account)
      g_plus_account.build_social_account(is_active:true, account_type: account_type)
      g_plus_account.save ? "Successfully created" : "Something wrong"
    else
      "Already exists. Social Item ID: #{SocialAccount.joins("LEFT JOIN google_plus_accounts ON social_accounts.social_item_id = google_plus_accounts.id AND social_item_type = 'GooglePlusAccount'").where("google_plus_accounts.google_account_id = ? AND social_accounts.account_type = ?", @google_account_activity.google_account.id, account_type).first.try(:id)}"
    end
    render json: response
  end

  def add_youtube_strike
    response = if request.body.present?
      json = JSON.load(request.body.read)
      youtube_channel_id = json["youtube_channel_id"].try(:strip)
      youtube_channel = youtube_channel_id.present? ? YoutubeChannel.by_youtube_channel_id(youtube_channel_id).first : nil
      if !youtube_channel.present?
        youtube_video_id = json["youtube_video_ids"].to_s.split(",").first.strip
        if youtube_video_id.present?
          youtube_channel = YoutubeVideo.find_by_youtube_video_id(youtube_video_id).try(:youtube_channel)
        end
      end
      if youtube_channel.present?
        json["strike"] = json["strike"].to_i
        json["email_body"] = json["email_body"].to_s.squeeze
        if youtube_channel.strike < json["strike"]
          youtube_channel.strike = json["strike"]
          youtube_channel.save
        end
        json["youtube_channel_id"] = youtube_channel.id
        youtube_strike = YoutubeStrike.where(youtube_channel_id: youtube_channel.id, strike: json["strike"]).first_or_initialize
        if Rails.env.production? && !youtube_strike.persisted?
          youtube_strike.attributes = json
          if youtube_strike.save
            youtube_strike.save_screenshots
            pushbullet_message = "Youtube channel ##{youtube_channel.id} with #{youtube_channel.strike} #{'strike'.pluralize(youtube_channel.strike)}: #{Rails.configuration.routes_default_url_options[:host]}#{Rails.application.routes.url_helpers.edit_youtube_channel_path(youtube_channel)}"
            Utils.pushbullet_broadcast("New youtube strike at #{Time.now}", pushbullet_message)
            BroadcasterMailer.new_youtube_channel_strike(youtube_channel.id)
            BotServer.kill_all_zenno
          end
        end
        {status: 200}
      else
        {status: 404}
      end
    else
      {status: 500}
    end
    render json: response
  end

  def youtube_audio_library
    response = if request.body.present?
      email_account = @google_account_activity.google_account.email_account
      username = email_account.email.strip.gsub("@gmail.com", "")
      bot_server_url = Setting.get_value_by_name("EmailAccount::BOT_URL")
      json = JSON.load(request.body.read)
      duration_array = json["duration"].split(":")
      genre_array = json["genre"].to_s.split(" | ")
      genre_string = genre_array.first.to_s.strip
      mood_string = genre_array.second.to_s.downcase.strip
      audio_file = bot_server_url + json["music_path"]
      audio_json = {
        title: json["title"].to_s.strip,
        duration: duration_array.first.to_f * 60 + duration_array.second.to_f,
        popularity: json["popularity"].to_f,
        monetization: json["monetization"],
        description: json["description"],
        attribution_required: json["attribution"] == "Attribution not required" ? Artifacts::Audio.attribution_required.find_value(:attribution_not_required).value : Artifacts::Audio.attribution_required.find_value(:attribution_required).value,
        license_type: json["attribution"] == "Attribution not required" ? Artifacts::Audio.license_type.find_value('Standard Youtube License').value : Artifacts::Audio.license_type.find_value('Creative Commons - Attribution').value,
        license_url: json["license_url"],
        source: json["source"],
        artist_url: json["artist_url"],
        sound_type: json["music_type"] == "Free music" ? Artifacts::Audio.sound_type.find_value(:sound_music).value : Artifacts::Audio.sound_type.find_value(:sound_effect).value,
        mood: Artifacts::Audio.mood.find_value(:"#{mood_string}").try(:value),
        audio_category: Artifacts::Audio.audio_category.find_value(json["category"].to_s.strip).try(:value)
      }
      artist = if json["artist"].to_s.strip.present?
        artist = Artifacts::Artist.where("LOWER(name) = ?", json["artist"].to_s.downcase.strip).first_or_initialize
        unless artist.persisted?
          artist.name = json["artist"].to_s.strip
          artist.url = json["artist_url"]
          artist.save
        end
        artist
      else
        nil
      end

      genre = if genre_string.present?
        genre = Genre.where("LOWER(name) = ?", genre_string.downcase).first_or_initialize
        unless genre.persisted?
          genre.name = genre_string
          genre.save
        end
        genre
      else
        nil
      end

      unless Artifacts::YoutubeAudio.where({title: audio_json[:title], artifacts_artist_id: artist.try(:id), duration: audio_json[:duration], sound_type: audio_json[:sound_type], audio_category: audio_json[:audio_category]}).present?
        audio = Artifacts::YoutubeAudio.new(audio_json)
				f = open(audio_file)
				audio.file = f
        audio.file_file_name = "#{audio.title}.mp3"
        audio.artist = artist
        if audio.save
          audio.genres << genre if genre.present?
          screenshot_name = bot_server_url + json["screen_path"].gsub(".jpg", "")
          ["#{screenshot_name}(Artist).jpg", "#{screenshot_name}(Source).jpg", "#{screenshot_name}(Attribution).jpg", "#{screenshot_name}.jpg"].each do |screenshot_path|
            screenshot = audio.save_screenshot(screenshot_path)
            if screenshot.present? && screenshot.image.present?
              begin
                screen = Screenshot.new
                screen.image = screenshot.image
                extension = Rack::Mime::MIME_TYPES.invert[screen.image_content_type]
                screen.image_file_name = File.basename(username)[0..-1] + extension
                screen.removable = false
                email_account.screenshots << screen
              rescue
              end
            end
          end
          puts "*** Audio #{json['number']} - #{json['title']} successfully saved. ***"
        else
          puts "---Audio #{json['number']} - #{json['title']} didn't save! ---"
        end
				f.close unless f.closed?
      else
        puts "Audio already exists!"
      end
      {status: 200}
    else
      {status: 500}
    end
    render json: response
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_google_account_activity
      @google_account_activity = GoogleAccountActivity.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def google_account_activity_params
      params.require(:google_account_activity).permit!
    end
end
