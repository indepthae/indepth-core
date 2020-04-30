namespace :fedena_transport do
  desc "Install Fedena Transport Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_transport/public ."
  end
end
