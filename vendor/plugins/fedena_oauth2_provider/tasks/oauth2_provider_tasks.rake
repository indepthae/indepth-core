namespace :fedena_oauth2_provider do
  desc "Install Fedena Oauth2 Provider"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_oauth2_provider/public ."
  end
end
