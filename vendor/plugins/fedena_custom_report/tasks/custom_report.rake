namespace :fedena_custom_report do
  desc "Install Fedena Custom Report Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_custom_report/public ."
  end
end