namespace :fedena_instant_fee do
  desc "Install Fedena Instant Fee Module"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_instant_fee/public ."
  end
end
