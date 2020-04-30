namespace :fedena_discipline do
  desc "Install Fedena Discipline Module"
  task :install do
    system "rsync -ruv --exclude=.svn vendor/plugins/fedena_discipline/public ."
  end
end
