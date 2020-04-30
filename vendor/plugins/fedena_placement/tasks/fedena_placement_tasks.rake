namespace :fedena_placement do
  desc "Install Fedena Placement Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_placement/public ."
  end
end
