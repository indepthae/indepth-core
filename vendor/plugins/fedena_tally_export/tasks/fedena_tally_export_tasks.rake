namespace :fedena_tally_export do
  desc "Install Fedena Tally Export Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_tally_export/public ."
  end
end
