namespace :fedena_fee_import do
  desc "Install Fedena Fee Import Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_fee_import/public ."
  end
end
