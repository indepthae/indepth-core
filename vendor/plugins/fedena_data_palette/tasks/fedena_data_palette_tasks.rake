namespace :fedena_data_palette do
  desc "Explaining what the task does"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_data_palette/public ."
  end
end
