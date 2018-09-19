# This file is used by Rack-based servers to start the application.
# --- Start of unicorn worker killer code ---

# require 'unicorn/worker_killer'
#
# max_request_min =  2000
# max_request_max =  2500
#
# # Max requests per worker
# use Unicorn::WorkerKiller::MaxRequests, max_request_min, max_request_max
#
# oom_min = (450) * (1024**2)
# oom_max = (500) * (1024**2)
#
# # Max memory size (RSS) per worker
# use Unicorn::WorkerKiller::Oom, oom_min, oom_max
#
# # --- End of unicorn worker killer code ---

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application
DelayedJobWeb.use Rack::Auth::Basic do |username, password|
  username == 'broadcaster'
  password == 'legalbistro'
end
