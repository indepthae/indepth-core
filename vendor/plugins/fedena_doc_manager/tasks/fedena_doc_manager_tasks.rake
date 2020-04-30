namespace :fedena_doc_manager do
  desc "Install Fedena Document Module"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_doc_manager/public ."
  end
end