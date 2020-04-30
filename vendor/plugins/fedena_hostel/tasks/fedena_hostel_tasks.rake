namespace :fedena_hostel do
  desc "Install Fedena Hostel Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_hostel/public ."
  end
end
