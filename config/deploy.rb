# config valid only for current version of Capistrano
lock '3.5'

set :application, 'broadcaster'
set :repo_url, 'git@bitbucket.org:valynteen_solutions/broadcaster.git'
set :user, 'broadcaster'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Default deploy_to directory is /var/www/my_app_name
set :deploy_to, "/home/broadcaster/#{fetch(:application)}"

set :pty,             true
set :use_sudo,        false
set :deploy_via,      :remote_cache
#puma configs
set :puma_threads,    [ENV['PUMA_THREADS_MIN'], ENV['PUMA_THREADS_MAX']]
set :puma_workers,    ENV['PUMA_WORKERS']
set :puma_bind,       "unix://#{fetch(:deploy_to)}/shared/tmp/sockets/#{fetch(:application)}-puma.sock"
set :puma_state,      "#{fetch(:deploy_to)}/shared/tmp/pids/puma.state"
set :puma_pid,        "#{fetch(:deploy_to)}/shared/tmp/pids/puma.pid"
set :puma_access_log, "#{fetch(:deploy_to)}/shared/log/puma.access.log"
set :puma_error_log,  "#{fetch(:deploy_to)}/shared/log/puma.error.log"
set :puma_preload_app, true
set :puma_worker_timeout, nil
set :puma_init_active_record, true  # Change to false when not using ActiveRecord
set :puma_default_hooks, -> { false }
#set :puma_conf, "#{fetch(:deploy_to)}/current/config/puma.rb"

# Default value for :scm is :git
set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, fetch(:linked_files, []).push('config/database.yml')

# Default value for linked_dirs is []
set :linked_dirs, fetch(:linked_dirs, []).push(
  'log', 'tmp/pids', 'tmp/cache', 'tmp/sockets', 'public/assets', 'public/system'
)
set :linked_files, %w(config/application.yml)

# set :unicorn_conf, "#{fetch(:deploy_to)}/current/config/unicorn.rb"
# set :unicorn_pid, "#{fetch(:deploy_to)}/shared/tmp/pids/unicorn.pid"

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

namespace :puma do
  desc 'Create Directories for Puma Pids and Socket'
  task :make_dirs do
    on roles(:web) do
      execute "mkdir #{fetch(:deploy_to)}/shared/tmp/sockets -p"
      execute "mkdir #{fetch(:deploy_to)}/shared/tmp/pids -p"
    end
  end

  before :start, :make_dirs
end

namespace :deploy do

  # make sure we're deploying what we think we're deploying
  # before :deploy, "deploy:check_revision"
  # only allow a deploy with passing tests to deployed
  # before :deploy, "deploy:run_tests"
  # compile assets locally then rsync
  # after 'deploy:symlink:shared', 'deploy:compile_assets_locally'
  before :deploy, 'deploy:send_start_notification'
  after :finishing, 'deploy:cleanup'
  after :finishing, 'deploy:send_finish_notification'

  # remove the default nginx configuration as it will tend
  # to conflict with our configs.
  # before 'deploy:setup_config', 'nginx:remove_default_vhost'

  # reload nginx to it will pick up any modified vhosts from
  # setup_config
  # after 'deploy:setup_config', 'nginx:reload'

  desc 'Initial Deploy'
  task :initial do
    on roles(:web) do
      before 'deploy:restart', 'puma:start'
    end
    on roles(:all) do
      invoke 'deploy'
    end
  end

  desc 'Send start notification'
  task :send_start_notification do
    sleep_time = 60
    on roles(:web) do
      within release_path do
        execute :bundle, :exec, "bin/rails runner -e #{fetch(:rails_env)} 'PusherService.deploy_started(#{sleep_time})'"
      end
    end
    sleep sleep_time
  end

  desc 'Send finish notification'
  task :send_finish_notification do
    on roles(:web) do
      within release_path do
        execute :bundle, :exec, "bin/rails runner -e #{fetch(:rails_env)} PusherService.deploy_finished"
        # execute 'cd /home/broadcaster/broadcaster/current && ( export RAILS_ENV="production" ; ~/.rvm/bin/rvm default do bundle exec bin/delayed_job -n 16 stop )'
      end
    end
  end

  desc 'Start Application'
  task :start do
    on roles(:web) do
      within release_path do
        #execute :bundle, :exec, "unicorn -c #{fetch(:unicorn_conf)} -E #{fetch(:rails_env)} -D"
        invoke 'puma:start'
      end
    end
    on roles(:dj_1) do
      within release_path do
        invoke 'delayed_job_1:start'
      end
    end
    # on roles(:dj_2) do
    #   within release_path do
    #     invoke 'delayed_job_2:start'
    #   end
    # end
    on roles(:dj_3) do
      within release_path do
        invoke 'delayed_job_3:start'
      end
    end
  end

  desc 'Stop Application'
  task :stop do
    on roles(:web) do
      within release_path do
        #execute "ps aux | grep 'unicorn' | awk '{print $2}' | xargs kill -9"
        invoke 'puma:stop'
      end
    end
    on roles(:dj_1) do
      within release_path do
        invoke 'delayed_job_1:stop'
      end
    end
    # on roles(:dj_2) do
    #   within release_path do
    #     invoke 'delayed_job_2:stop'
    #   end
    # end
    on roles(:dj_3) do
      within release_path do
        invoke 'delayed_job_3:stop'
      end
    end
  end

  desc 'Restart application'
  task :restart do
    on roles(:web) do
      within release_path do
        #execute "ps aux | grep 'unicorn' | awk '{print $2}' | xargs kill -9"
        #execute :bundle, :exec, "unicorn -c #{fetch(:unicorn_conf)} -E #{fetch(:rails_env)} -D"
        #invoke 'deploy:puma_killing_restart'
        invoke 'puma:stop'
        sleep 5
        invoke 'puma:start'
      end
    end
    on roles(:dj_1) do
      within release_path do
        invoke 'delayed_job_1:restart'
      end
    end
    # on roles(:dj_2) do
    #   within release_path do
    #     invoke 'delayed_job_2:restart'
    #   end
    # end
    on roles(:dj_3) do
      within release_path do
        invoke 'delayed_job_3:restart'
      end
    end
  end

  desc "Update the crontab file"
  task :update_crontab do
    # on roles(:dj_2) do
    on roles(:dj_3) do
      within release_path do
				with rails_env: fetch(:rails_env) do
        	execute :bundle, :exec, "whenever -w RAILS_ENV=#{fetch(:rails_env)}"
				end
      end
    end
  end

  desc "Puma restart (by killing)"
  task :puma_killing_restart do
    on roles(:web) do
      within release_path do
        #execute "ps aux | grep 'puma' | awk '{print $2}' | xargs kill -9"
        execute "pkill -f puma"
        sleep 2
        invoke 'puma:start'
      end
    end
  end

  # task :update_crontab, :roles => :db do
  #   run "cd #{release_path} && whenever --update-crontab #{application}"
  # end

  after :publishing, :restart
  after :restart, :update_crontab

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
