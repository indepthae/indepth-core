namespace :fedena_app_frame do
  desc "Install Fedena App Frame Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_app_frame/public ."
  end
end
