namespace :fedena_form_builder do
  desc "Install Fedena Form Builder Module"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_form_builder/public ."
  end
end