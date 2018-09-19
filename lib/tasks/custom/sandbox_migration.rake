namespace :sandbox_migration do
  task migrate: :environment do
    SandboxMigration::Migration.migrate
  end
  task fix_video_ids: :environment do
    SandboxMigration::Migration.fix_video_ids
  end
end
