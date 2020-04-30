namespace :fedena_task do
  desc "Install Fedena Task Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_task/public ."
  end


  desc "Update Paths for Task Module"
  task :update_plugins_paths => :environment do

    models = [Task,TaskComment]
    sub_paths = {
      "Task" => "uploads/tasks",
      "TaskComment" => "uploads/task_comments"
    }
    log = Logger.new("log/paperclip_path_update.log")
    models.each do |model|
      begin
      
        log.debug("#{model}")
        model.send :include, PaperclipPathUpdate
        model.attachment_definitions.each do |d|
          if model.connection.select_all("select * from #{model.table_name} where attachment_file_name is not NULL;").present?
            sub_path1_old = sub_paths["#{model}"]
            sub_path1 = sub_path1_old.gsub("#{model.table_name}","#{model.table_name}_backup")
            File.rename "#{sub_path1_old}", "#{sub_path1}"

            arr = Dir["#{sub_path1}/*/"].map {|a| File.basename(a) }
            arr.each do |arr_l|
              arri = Dir["#{sub_path1}/#{arr_l}/*/"].map {|a| File.basename(a) }
              arri.each do |arri_l|
                begin
                  rec = model.find_without_school arri_l.to_i
                  file_type = "#{d.first}_file_name"
                  if rec.present? and rec[file_type].present?
                    file = "#{sub_path1}/#{arr_l}/#{arri_l}/#{rec[file_type]}"
                    if File.exists? file
                      rec.attachment = File.open(file)
                      rec.send :update_without_callbacks
                      unless rec.save_attached_files
                        log.debug("#{rec.id}----#{rec.errors.full_messages}")
                      end
                    end
                  end
                rescue Exception => err
                  log.debug("#{err.message}")
                  log.debug("------------")
                  log.debug("#{err.backtrace.inspect}")
                end
              end
            end
            # BELOW 3 lines can delete backup folder after successful moving of files to new location
            #            if File.exists? sub_path1
            #              FileUtils.rm_r sub_path1
            #            end
          end
        end

      rescue Exception => e
        puts e
        puts "Failed to complete task! Reverting process"
        sub_path1_old = sub_paths["#{model}"]
        sub_path1 = sub_path1_old.gsub("#{model.table_name}","#{model.table_name}_backup")

        if File.exists? sub_path1
          puts "Restoring old data of #{model.table_name} module"
          if File.exists? sub_path1_old
            FileUtils.rm_r sub_path1_old
          end
          File.rename "#{sub_path1}","#{sub_path1_old}"
        end

      end

    end

  end

end
