namespace :acts_as_multi_school do

  desc "Migrate school tables for multischool"
  task :migrate => :environment do
    ActiveRecord::Migrator.migrate("vendor/plugins/acts_as_multi_school/db/migrate/", ENV["VERSION"] ? ENV["VERSION"].to_i : nil)
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  desc "Make new migration file adding school_id into new models"
  task :build_migrations => :environment do
    MultiSchoolMigration::MakeMigration.new.make_migration
  end

  desc "Rollback multischool migrations"
  task :rollback => :environment do
    ActiveRecord::Migrator.rollback("vendor/plugins/acts_as_multi_school/db/migrate/", ENV["STEP"] ? ENV["STEP"].to_i : 1)
    Rake::Task["db:schema:dump"].invoke if ActiveRecord::Base.schema_format == :ruby
  end

  desc "Copying assets"
  task :asset_copy do
    system "rsync --exclude=.svn -ruv vendor/plugins/acts_as_multi_school/public ."
  end

  desc "Remove cached js"
  task :remove_cached_js do
    File.delete("public/javascripts/cache/javascripts/all.js") if File.exists?("public/javascripts/cache/javascripts/all.js")
  end

  desc "Creating default data"
  task :create_default_data do
    settings = MultiSchool.multischool_settings
    unless MultiSchoolGroup.exists?
      admin = MultiSchoolAdmin.find_or_create_by_username(:username=>"admin",:password=>"foradian",:email=>settings['email'],:full_name=>"Administrator", :contact_no=>settings['contact_num'])
      group = MultiSchoolGroup.find_or_create_by_name(:name=>settings["organization_details"]["name"],:license_count=>settings["max_school_count"],:whitelabel_enabled=>settings["organization_details"]["whitelabel"],:school_stats_enabled=>settings["organization_details"]["school_stats"],:gps_enabled=>settings["organization_details"]["gps_enabled"])
      admin.multi_school_group = group
      group.school_domains.build(:domain=>(settings["domain"]||"lvh.me"))
      group.save
    end
  end
  
end

namespace :fedena do
  desc "Multischool - Full setup"
  task :install_multischool => :environment do
    Rake::Task["db:migrate"].execute
    Rake::Task["fedena:plugins:db:migrate"].execute
    Rake::Task["fedena:plugins:asset_copy"].execute
    Rake::Task["acts_as_multi_school:migrate"].execute
    Rake::Task["acts_as_multi_school:build_migrations"].execute
    Rake::Task["acts_as_multi_school:migrate"].execute
    Rake::Task["acts_as_multi_school:create_default_data"].execute
    Rake::Task["acts_as_multi_school:asset_copy"].execute
    Rake::Task["acts_as_multi_school:remove_cached_js"].execute
  end

  desc "Multischool - run db seed for all plugins for all existing schools"
  task :seed_schools => :environment do
    School.find_in_batches do |schools|
      schools.each do |s|
        s.create_fedena_school_seed
        School.update_all({:last_seeded_at => Time.now},{:id  => s.id})
      end
    end
    Rake::Task["fedena:records:update"].execute
  end
  
  namespace :plugins do
    
    desc "Run plugin install rake tasks all fedena plugins"
    task :asset_copy => :environment do
      FedenaPlugin::AVAILABLE_MODULES.each do |m|
        Rake::Task["#{m[:name]}:install"].execute
      end
    end
    
  end

end
