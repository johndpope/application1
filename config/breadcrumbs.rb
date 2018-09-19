crumb :root do
  link "Broadcaster", root_path
end

crumb :statistics do
  link "Statistics"
end

crumb :youtube_monthly_statistics do |month, year|
  parent :statistics
  link "Youtube monhtly statistics", youtube_monthly_statistics_path(year, month)
end

crumb :tools do
  link "Tools"
end

crumb :password_generator do
  parent :tools
  link "Password generator", password_generator_path
end

crumb :video_production do
  link "Video Production"
end

crumb :source_videos do
  parent :video_production
  link "Source Videos"
end

crumb :video_scripts do
  parent :video_production
  link "Video scripts", video_scripts_path
end

crumb :transitions do
  parent :video_production
  link "Transitions", transitions_path
end

crumb :sales_pitches do
  parent :video_production
  link "Sales pitches", sales_pitches_path
end

crumb :assets do
  link "Assets", host_machines_path
end

crumb :host_machine do
  parent :assets
  link "Host Machines", host_machines_path
end

crumb :email_accounts do
  parent :assets
  link "Email Accounts", email_accounts_path
end

crumb :email_accounts do
  parent :assets
  link "Email Accounts", email_accounts_path
end

crumb :youtube_channels do
  parent :assets
  link "Youtube Channels", youtube_channels_path
end

crumb :youtube_videos do
  parent :assets
  link "Youtube Videos", youtube_videos_path
end

crumb :show_host_machine do |hm|
  parent :host_machine
  link "Host Machine #{hm.url}", show_host_machine_path(hm)
end

crumb :dashboard do
  link "Dashboard", dashboard_path
end

crumb :content do
	link "Content"
end

crumb :blending_patterns do
	link "Blending Patterns"
end
