def delayed_job_sh_part
  '#!/bin/bash\n### BEGIN INIT INFO\n# Provides:          delay-job\n# Required-Start:    $remote_fs $syslog\n# Required-Stop:     $remote_fs $syslog\n# Default-Start:     2 3 4 5\n# Default-Stop:      0 1 6\n# Short-Description: Start delayed jobs at boot time\n# Description:       Enable service provided by daemon.\n### END INIT INFO\ncd /home/broadcaster/broadcaster/current && ( export RAILS_ENV="production" ; ~/.rvm/bin/rvm default do bundle exec bin/delayed_job stop )\ncd /home/broadcaster/broadcaster/current && ( export RAILS_ENV="production" ; ~/.rvm/bin/rvm default do bundle exec bin/delayed_job '
end

namespace :delayed_job_1 do
  # def args_1
  #   '--pool=grab_youtube_statistics,crawler_add_info,dealers_crawling,start_channels_process,other,save_screenshot,save_profile_cache,soundtrack,recovery_inbox_emails:30 --pool=artifacts_image_import,retrieve_gps_from_image_files:20'
  # end
  def args_1
    '--pool=grab_youtube_statistics,crawler_add_info,dealers_crawling,start_channels_process,other,save_screenshot,save_profile_cache,soundtrack,recovery_inbox_emails:20 --pool=artifacts_image_import,retrieve_gps_from_image_files:10 --pool=templates_aae_project_create,templates_dynamic_aae_projects_sandbox_project_generation_job:10 --pool=blend_video_set:10 --pool=templates_dynamic_aae_project_replace,templates_aae_project_validate_texts,templates_aae_project_validate_images:10'
  end

  desc 'Stop the delayed_job #1 process'
  task :stop do
    on roles(:dj_1) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
        end
      end
    end
  end

  desc 'Start the delayed_job #1 process'
  task :start do
    on roles(:dj_1) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', args_1, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_1 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end

  desc 'Restart the delayed_job #1 process'
  task :restart do
    on roles(:dj_1) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
          execute :bundle, :exec, :'bin/delayed_job', args_1, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_1 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end
end

namespace :delayed_job_2 do
  def args_2
    '--pool=templates_aae_project_create,templates_dynamic_aae_projects_sandbox_project_generation_job:10 --pool=blend_video_set:10 --pool=templates_dynamic_aae_project_replace,templates_aae_project_validate_texts,templates_aae_project_validate_images:10 --pool=rendering_machine_take_output_video,rendering_machine_remove_output_video,rendering_machine_ame_log,rendering_machine_grab_info,create_media_info:20'
  end

  desc 'Stop the delayed_job #2 process'
  task :stop do
    on roles(:dj_2) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
        end
      end
    end
  end

  desc 'Start the delayed_job #2 process'
  task :start do
    on roles(:dj_2) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', args_2, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_2 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end

  desc 'Restart the delayed_job #2 process'
  task :restart do
    on roles(:dj_2) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
          execute :bundle, :exec, :'bin/delayed_job', args_2, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_2 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end
end

namespace :delayed_job_3 do
  # def args_3
  #   '--pool=artifacts_image_aspect_cropping_variations,update_geo_info,artifacts_generate_image_croppings,artifacts_fix_orig_image_orientation:20 --pool=youtube_create_video,youtube_create_video_thumbnail_for_generated_video:27 --pool=templates_dynamic_aae_project_generate_test_project_job,templates_dynamic_aae_projects_test_project_generation_job:3'
  # end
  def args_3
    '--pool=artifacts_image_aspect_cropping_variations,update_geo_info,artifacts_generate_image_croppings,artifacts_fix_orig_image_orientation:10 --pool=youtube_create_video,youtube_create_video_thumbnail_for_generated_video:17 --pool=templates_dynamic_aae_project_generate_test_project_job,templates_dynamic_aae_projects_test_project_generation_job:3 --pool=rendering_machine_take_output_video,rendering_machine_remove_output_video,rendering_machine_ame_log,rendering_machine_grab_info,create_media_info:20'
  end


  desc 'Stop the delayed_job #3 process'
  task :stop do
    on roles(:dj_3) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
        end
      end
    end
  end

  desc 'Start the delayed_job #3 process'
  task :start do
    on roles(:dj_3) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', args_3, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_3 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end

  desc 'Restart the delayed_job #3 process'
  task :restart do
    on roles(:dj_3) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          execute :bundle, :exec, :'bin/delayed_job', :stop
          execute :bundle, :exec, :'bin/delayed_job', args_3, :start
          #auto update delay-job.sh script
          execute "echo -e '#{delayed_job_sh_part + args_3 + ' start )'}' > ~/delay-job.sh"
          execute "chmod 755 ~/delay-job.sh"
        end
      end
    end
  end
end
