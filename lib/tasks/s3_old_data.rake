task :s3_old_data => :environment do
  require 'logger'
  start_time = Time.now
  log = Logger.new('log/s3_old_data.log')
  log.info('====================================================================')
  log.info("Starting at #{start_time}")
  log.info('====================================================================')  
  core_tables = ["additional_report_csvs", "students", "employees", "archived_students", "archived_employees", "school_details",     
    "batch_wise_student_reports","news_attachments","record_addl_attachments","reminder_attachments", "student_attachments"]
  plugin_tables = ["applicant_addl_attachments", "applicants", "assignment_answers", "assignments", "data_exports",
    "discipline_attachments", "documents", "form_file_attachments", "gallery_photos", "group_files", "imports", "tally_export_files",
    "student_addl_attachments", "task_comments", "tasks", "applicant_addl_values", "auto_allocation_fet_run_logs", "groups"]
  public_tables=["redactor_uploads"]
  all_tables = core_tables + plugin_tables + public_tables
  all_attachment_models = ActiveRecord::Base.send(:subclasses).select {|x| x.attachment_definitions.present? }  
#  all_tables = public_tables 
  all_tables = all_attachment_models.map {|x| x.table_name }
  public_tables = (public_tables & all_tables).present? ? public_tables : []
  active_school_files = 0
  inactive_school_files = 0
  rb = 0
  total_schools = 0
  active_schools = 0
  School.find_in_batches(:batch_size => 1000) do |schools|
    rb = rb.next
    log.info("=======schools found in BatchIteration##{rb} : #{schools.length}")
    total_schools = schools.length
    schools.each do |school|
      school_is_active = !(school.is_deleted)
      active_schools += 1 if school_is_active
      log.info("================================")
      MultiSchool.current_school = school
      log.info("=====Current School: #{school.id} <#{school.name} (#{school.code})> ")
      log.info("================================")
      all_tables.each do |m|
        s3_directory = (public_tables.include?(m) ? "s3_uploads_#{school_is_active ? 'active' : 'inactive'}/public/" : "s3_uploads_#{school_is_active ? 'active' : 'inactive'}/private/" )
        if ActiveRecord::Base.connection.tables.include?(m)
          begin
            model_name = m.classify.constantize
            #          table_name = m
            if model_name.attachment_definitions.present?
              model_name.attachment_definitions.each_pair do |attachment_name, attachment_def|              
                i = 0
                files_count = 0
                log.info("#{m.classify} :: #{attachment_name}")
                model_name.find_in_batches(:batch_size => 1000, :conditions => "#{attachment_name}_file_name is not NULL") do |records|              
                  i = i.next
                  log.info("RecordBatch#{i} : fetched #{records.length} records with attachments set")
                  records.each do |record|       
                    record_id = record.send("id")
#                    puts "record##{record_id}"
                    log.info("record##{record_id}")
                    attachment_updated_at=record.send("#{attachment_name}_updated_at").try(:strftime, '%Y%m%d%H%m%S')
                    attachment_new_path=record.send("#{attachment_name}").path                
                    attachment_old_path="#{RAILS_ROOT}/"+attachment_new_path #.gsub("/#{attachment_updated_at}", "")                
                    path_definition = attachment_def[:path]                    
                    file_name = File.basename(attachment_new_path)
                    file_copy_to_name = URI.unescape(file_name) #.gsub('+','%2B')
                    path_arr = attachment_new_path.split('/')
                    file_path = path_arr.slice(0,path_arr.length - 1).join('/')                                        
                    file_exists = false
                    if File.exists?("#{file_path}/#{file_name}")                      
                      file_copy_name = file_name
                      file_exists = true
                    elsif File.exists?("#{file_path}/#{URI.unescape(file_name)}")                      
                      file_copy_name = URI.unescape(file_name)                      
                      file_exists = true
                    elsif File.exists?("#{file_path}/#{URI.unescape(URI.unescape(file_name))}")                      
                      file_copy_name = URI.unescape(URI.unescape(file_name))
                      file_exists = true
                    elsif File.exists?("#{file_path}/#{CGI.escape(file_name)}")                      
                      file_copy_name = CGI.escape(file_name)
                      file_exists = true                      
                    end
                    if file_exists #File.exist?("#{attachment_old_path}")                             
                      log.info("File found ? #{file_exists}")    
                      log.info("Actual file name as in db #{file_name}")
                      log.info("Actual file name as in file system #{file_copy_name}")
                      log.info("File to be copied with name #{file_copy_to_name}")
                      path_parts = "#{file_path}/#{file_name}".split('/') #attachment_new_path.split('/')
                      j = 0
                      path_val = []
                      path_definition.split('/').each_with_index do |el,i|
                        if el == ":school_id" || el == ":id_partition"
                          path_val << "#{path_parts[j]}#{path_parts[j+1]}#{path_parts[j+2]}".to_i
                          j = j + 3
                        else
                          path_val << path_parts[j]
                          j = j + 1
                        end
                      end
                      path_val[path_val.length - 1] = "#{attachment_updated_at}/#{path_val[path_val.length - 1]}"                      
                      attachment_modified_path = path_val.join('/')
                      file_name=File.basename(attachment_old_path)
                      new_attachment_dir_path=s3_directory + attachment_modified_path.gsub(file_name,'')
                      FileUtils.mkdir_p(new_attachment_dir_path)
                      
                      previous_attachment_updated_at = Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}")
                      if previous_attachment_updated_at
                        if previous_attachment_updated_at != attachment_updated_at                      
                          Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}") { attachment_updated_at }                      
#                          FileUtils.cp(attachment_old_path,new_attachment_dir_path)                                            
                          FileUtils.cp("#{file_path}/#{file_copy_name}","#{new_attachment_dir_path}/#{file_copy_to_name}")                    
                          files_count = files_count.next
                        end
                      else
                        Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}") { attachment_updated_at }                  
#                        FileUtils.cp(attachment_old_path,new_attachment_dir_path)                    
                        FileUtils.cp("#{file_path}/#{file_copy_name}","#{new_attachment_dir_path}/#{file_copy_to_name}")                    
                        files_count = files_count.next
                      end                  
                    else
                      log.info("File found ? #{file_exists}")    
                    end

                    if record.send("#{attachment_name}").options[:styles].present?
                      log.info("Styles present")
                      record.send("#{attachment_name}").options[:styles].each_pair do |k,v|
                        attachment_new_path=record.send("#{attachment_name}").path(k)
                        attachment_old_path="#{RAILS_ROOT}/"+attachment_new_path #.gsub("/#{attachment_updated_at}", "")
                        file_name = File.basename(attachment_new_path)
                        path_arr = attachment_new_path.split('/')
                        file_path = path_arr.slice(0,path_arr.length - 1).join('/')                                        
                        file_exists = false
                        if File.exists?("#{file_path}/#{file_name}")                      
                          file_copy_name = file_name
                          file_exists = true
                        elsif File.exists?("#{file_path}/#{URI.unescape(file_name)}")                      
                          file_copy_name = URI.unescape(file_name)                      
                          file_exists = true
                        elsif File.exists?("#{file_path}/#{URI.unescape(URI.unescape(file_name))}")                      
                          file_copy_name = URI.unescape(URI.unescape(file_name))
                          file_exists = true
                        elsif File.exists?("#{file_path}/#{CGI.escape(file_name)}")                      
                          file_copy_name = CGI.escape(file_name)
                          file_exists = true                      
                        end
# store file with escaped name                        
                        if file_exists     
#                          files_count = files_count.next
                          path_parts = "#{file_path}/#{file_name}".split('/')
                          j = 0
                          path_val = []
                          path_definition.split('/').each_with_index do |el,i|
                            if el == ":school_id" || el == ":id_partition"
                              path_val << "#{path_parts[j]}#{path_parts[j+1]}#{path_parts[j+2]}".to_i
                              j = j + 3
                            else
                              path_val << path_parts[j]
                              j = j + 1
                            end
                          end
                          path_val[path_val.length - 1] = "#{attachment_updated_at}/#{path_val[path_val.length - 1]}"
                          attachment_modified_path = path_val.join('/')
                      
                          file_name=File.basename(attachment_old_path)
                          new_attachment_dir_path = s3_directory + attachment_modified_path.gsub(file_name,'')
                          FileUtils.mkdir_p(new_attachment_dir_path)
#                          FileUtils.cp(attachment_old_path,new_attachment_dir_path)
                          previous_attachment_updated_at = Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}")
                          if previous_attachment_updated_at
                            if previous_attachment_updated_at != attachment_updated_at
                              Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}") { attachment_updated_at }
                              FileUtils.cp(attachment_old_path,new_attachment_dir_path)                      
                              FileUtils.cp("#{file_path}/#{file_copy_name}","#{new_attachment_dir_path}/#{file_copy_to_name}")                    
                              files_count = files_count.next
                            end
                          else
                            Rails.cache.fetch(:"s3_migration:#{new_attachment_dir_path}") { attachment_updated_at }                  
#                            FileUtils.cp(attachment_old_path,new_attachment_dir_path)                        
                            FileUtils.cp("#{file_path}/#{file_copy_name}","#{new_attachment_dir_path}/#{file_copy_to_name}")                    
                            files_count = files_count.next
                          end
                        end
                      end
                    else
                      log.info("No styles found")
                    end
                  end
                end
                log.info("files to migrate : #{files_count}")
                inactive_school_files += school_is_active ? 0 : files_count
                active_school_files += school_is_active ? files_count : 0
              end
            end
          rescue Exception => e
            p e
            log.info(e)
          end
        end
      end
    end
  end
  log.info("Total modules with attachment definitions : #{all_tables.length}")
  log.info("Total schools : #{total_schools}")
  log.info("Total active schools : #{active_schools}")
  log.info("Active schools files to be migrated :: #{active_school_files}")
  log.info("Inactive schools files to be migrated :: #{inactive_school_files}")
  end_time = Time.now
  log.info("Started at #{start_time}")
  log.info("Stopped at #{end_time}")
  log.info("Finished in #{end_time - start_time} ms")
end
