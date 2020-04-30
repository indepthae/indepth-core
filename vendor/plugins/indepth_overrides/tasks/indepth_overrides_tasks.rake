namespace :indepth_overrides do
  desc "Install Indepth Overrides"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/indepth_overrides/public ."
  end

  desc "Migrate all migrations in indepth_overrides plugin"
	task :migrate => :environment do
    ActiveRecord::Migrator.migrate("vendor/plugins/indepth_overrides/db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
	end
end
