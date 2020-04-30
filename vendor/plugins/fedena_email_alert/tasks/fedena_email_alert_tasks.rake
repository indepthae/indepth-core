namespace :fedena_email_alert do
  desc "Install Fedena Email Alert Plugin Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_email_alert/public ."
  end
end
