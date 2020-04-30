class RecordUpdate < ActiveRecord::Base

  validates_uniqueness_of :file_name, :scope=> [:school_id]

  def self.update_normal    
    update_normal_run
  end

  def self.update_school
    update_school_run(nil)
  end

  class << self
    def update_normal_run
      #core
      records_update_files = Dir["#{Rails.root}/db/seeds/*.rb"].sort
      # find all (normal / school) seeds executed previously
      executed_record_update_files = RecordUpdate.all(:conditions=>{:school_id => nil}, :select => "file_name").map { |ru| ru.file_name.split('/').last }
      records_update_files.each do |r_u|
        # skip the seed file for iteration if already executed successfully and recorded in record_updates
        next if executed_record_update_files.include?(r_u.split('/').last)        
        if confirmed_task(File.basename(r_u), nil)
          begin
            with_transaction {load(r_u)}
            p "===========#{File.basename(r_u)} Finished"
          rescue Exception => e
            p "===========#{File.basename(r_u)} Reverted"
            p "#{e}"
            revert_confirmed_task(File.basename(r_u), nil)
          end
        end
      end        
      #plugins
      FedenaPlugin::AVAILABLE_MODULES.each do |m|
        plugin_records_update_files = Dir["#{Rails.root}/vendor/plugins/#{m[:name]=='fedena_google_sso' ? 'fedena_oauth' : m[:name]}/db/seeds/*.rb"].sort
        plugin_records_update_files.each do |r_u|
          # skip the seed file for iteration if already executed successfully and recorded in record_updates
          next if executed_record_update_files.include?(r_u.split('/').last)           
          if confirmed_task(File.basename(r_u), nil)
            begin
              with_transaction {load(r_u)}
              p "===========#{File.basename(r_u)} Finished"
            rescue Exception => e
              p "===========#{File.basename(r_u)} Reverted"
              p "#{e}"
              revert_confirmed_task(File.basename(r_u), nil)
            end
          end
        end
      end
    end

    def update_school_run(s_id)
      #core      
      records_update_files = Dir["#{Rails.root}/db/seeds/school/*.rb"].sort
      # find all (normal / school) seeds executed previously
      executed_record_update_files = RecordUpdate.all(:conditions=>{:school_id => s_id}, :select => "file_name").map { |ru| ru.file_name.split('/').last }            
      records_update_files.each do |r_u|
        # skip the seed file for iteration if already executed successfully and recorded in record_updates
        next if executed_record_update_files.include?(r_u.split('/').last)        
        if confirmed_task(File.basename(r_u), s_id)
          begin
            with_transaction {load(r_u)}
            if s_id.nil?
              p "===========#{File.basename(r_u)} Finished"
            else
              p "===========#{File.basename(r_u)} Finished for school #{s_id}"
            end
          rescue Exception => e
            if s_id.nil?
              p "===========#{File.basename(r_u)} Reverted"
            else
              p "===========#{File.basename(r_u)} Reverted for school #{s_id}"
            end
            p "#{e}"
            revert_confirmed_task(File.basename(r_u), s_id)
          end
        end        
      end
      #plugins
      FedenaPlugin::AVAILABLE_MODULES.each do |m|
        plugin_records_update_files = Dir["#{Rails.root}/vendor/plugins/#{m[:name]=='fedena_google_sso' ? 'fedena_oauth' : m[:name]}/db/seeds/school/*.rb"].sort        
        plugin_records_update_files.each do |r_u|
          # skip the seed file for iteration if already executed successfully and recorded in record_updates
          next if executed_record_update_files.include?(r_u.split('/').last)
          if confirmed_task(File.basename(r_u), s_id)
            begin
              with_transaction {load(r_u)}
              if s_id.nil?
                p "===========#{File.basename(r_u)} Finished"
              else
                p "===========#{File.basename(r_u)} Finished for school #{s_id}"
              end
            rescue Exception => e
              if s_id.nil?
                p "===========#{File.basename(r_u)} Reverted"
              else
                p "===========#{File.basename(r_u)} Reverted for school #{s_id}"
              end
              p "#{e}"
              revert_confirmed_task(File.basename(r_u), s_id)
            end
          end          
        end  
      end
    end

    def with_transaction (&block)
      RecordUpdate.transaction do
        yield if block_given?
      end
    end

    def confirmed_task(file_name, school_id)
      record_update = RecordUpdate.new(:file_name=>file_name, :school_id=>school_id)
      return record_update.save
    end

    def revert_confirmed_task(file_name, school_id)
      record_update = RecordUpdate.find(:first, :conditions=>{:file_name=>file_name, :school_id=>school_id})
      record_update.destroy if record_update.present?
    end
  end
end