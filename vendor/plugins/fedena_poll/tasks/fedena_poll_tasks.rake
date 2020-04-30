namespace :fedena_poll do
  desc "Install Fedena Poll Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_poll/public ."
  end
end
