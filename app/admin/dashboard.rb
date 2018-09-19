ActiveAdmin.register_page "Dashboard" do
  
  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do

      columns do
            column do
                  panel 'API Operations' do
=begin
                        @delayed_job_statistics = JSON.parse(ActiveRecord::Base.connection.execute('SELECT delayed_jobs_statistics_json() AS result')[0]['result'])
                        columns do
                              column do
                                    ul do
                                          li do
                                                span 'Total Operations:'
                                                status_tag @delayed_job_statistics['total_jobs'].to_s, :ok, class:'dashboard-counter'
                                          end
                                          ul do
                                                li do
                                                      span 'Youtube Videos:'
                                                      status_tag @delayed_job_statistics['total_upload_youtube_video_jobs'].to_s, :ok, class:'dashboard-counter'
                                                end
                                                li do
                                                      span 'Youtube Video Thumbnails:'
                                                      status_tag @delayed_job_statistics['total_upload_youtube_video_thumbnail_jobs'].to_s, :ok, class:'dashboard-counter'
                                                end
                                          end
                                    end
                              end
                              column do
                                    ul do
                                          li do
                                                span 'Failed Operations:'
                                                status_tag Delayed::Job.where('last_error IS NOT NULL OR locked_at IS NOT NULL').count.to_s, :ok, class:'dashboard-counter'
                                          end
                                          ul do
                                                li do
                                                      span 'Youtube Videos:'
                                                      status_tag @delayed_job_statistics['failed_upload_youtube_video_jobs'].to_s, :ok, class:'dashboard-counter'
                                                end
                                                li do
                                                      span 'Youtube Video Thumbnails:'
                                                      status_tag @delayed_job_statistics['failed_upload_youtube_video_thumbnail_jobs'].to_s, :ok, class:'dashboard-counter'
                                                end
                                          end
                                    end
                              end
                        end
=end
                  end
            end
            column do
                  panel 'Google Accounts Statistics' do
=begin
                        @google_account_statistics = GoogleAccount.statistics
                        div do
                              ul do 
                                    li do
                                          span 'Total Accounts: '
                                          status_tag @google_account_statistics["total_count"].to_s, :ok, class:'dashboard-counter'
                                    end
                                    li do 
                                          span 'Active Accounts: '
                                          status_tag @google_account_statistics["active_accounts"].to_s, :ok, class:'dashboard-counter' 
                                    end
                                    ul do
                                          li do 
                                                span 'Tier 1 Accounts: '
                                                status_tag @google_account_statistics["active_tier1_accounts"].to_s, :ok, class:'dashboard-counter' 
                                          end
                                          li do
                                                span 'Tier 2 Accounts: '
                                                status_tag @google_account_statistics["active_tier2_accounts"].to_s, :ok, class:'dashboard-counter' 
                                          end
                                          li do
                                                span 'Tier 3 Accounts: '
                                                status_tag @google_account_statistics["active_tier3_accounts"].to_s, :ok, class:'dashboard-counter' 
                                          end
                                    end
                              end
                        end
=end
                  end
            end
            column do
                  panel 'Video Statistics' do
=begin
                        @youtube_video_statistics = YoutubeVideo.statistics
                        columns do
                                column do
                                    ul do
                                          li do
                                                span 'Total Uploaded Videos: '
                                                status_tag @youtube_video_statistics["total_videos"].to_s, :ok, class: 'dashboard-counter'
                                          end
                                          ul do
                                                li do
                                                      span 'Tier 1 Account Videos: '
                                                      status_tag @youtube_video_statistics["total_tier1_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                                li do
                                                      span 'Tier 2 Account Videos: '
                                                      status_tag @youtube_video_statistics["total_tier2_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                                li do
                                                      span 'Tier 3 Account Videos: '
                                                      status_tag @youtube_video_statistics["total_tier3_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                          end
                                    end
                                end   
                                column do
                                    ul do
                                          li do
                                                span 'Today Uploaded Videos: '
                                                status_tag @youtube_video_statistics["today_videos"].to_s, :ok, class:'dashboard-counter'
                                          end
                                          ul do
                                                li do
                                                      span 'Tier 1 Account Videos: '
                                                      status_tag @youtube_video_statistics["today_tier1_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                                li do
                                                      span 'Tier 2 Account Videos: '
                                                      status_tag @youtube_video_statistics["today_tier2_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                                li do
                                                      span 'Tier 3 Account Videos: '
                                                      status_tag @youtube_video_statistics["today_tier3_account_videos"].to_s, :ok, class: 'dashboard-counter'
                                                end
                                          end
                                    end
                                end
                        end
=end
                  end
            end
      end
    
    div id:'dashboard_map' do
      div id:'statistics' do
            render 'video_map'
            panel 'Video Uploads' do
                  div id:'video_uploads_chart' do
                  end
            end
      end
    end
  end
end
