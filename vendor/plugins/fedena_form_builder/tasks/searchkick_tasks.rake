require "rake"

namespace :searchkick do

  desc "reindex model"
  task :reindex => :environment do
    if ENV["CLASS"]
      klass = ENV["CLASS"].constantize rescue nil
      if klass
        klass.class_eval{def insert_school_id;;end} if MultiSchool rescue nil
        klass.reindex
      else
        abort "Could not find class: #{ENV["CLASS"]}"
      end
    else
      abort "USAGE: rake searchkick:reindex CLASS=Product"
    end
  end

  if defined?(Rails)

    namespace :reindex do
      desc "reindex all models"
      task :all => :environment do
#        Rails.application.eager_load!
        (Searchkick::Reindex.instance_variable_get(:@descendents) || []).each do |model|
          model.class_eval{def insert_school_id;;end} if MultiSchool rescue nil
          puts "Reindexing #{model.name}..."
          model.reindex
        end
        puts "Reindex complete"
      end
    end

  end

end
