namespace :fedena_online_exam do
  desc "Install Fedena Online Exam Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_online_exam/public ."
  end
end
