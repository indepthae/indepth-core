namespace :fedena_pay do
  desc "Install Fedena Pay Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_pay/public ."
  end
end
