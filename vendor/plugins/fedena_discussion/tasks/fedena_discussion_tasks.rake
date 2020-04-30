namespace :fedena_discussion do
  desc "Install Fedena Discussion Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_discussion/public ."
  end

  task :update_plugins_paths => :environment do
    models = [GroupFile]
    sub_paths = {
      "Group" => "uploads/groups/logos/",
      "GroupFile" => "uploads/group_files/docs"
    }
    sub_paths_old = {
      "Group" => "uploads/groups",
      "GroupFile" => "uploads/group_files"
    }
    log = Logger.new("log/paperclip_path_update.log")

    models.each do |model|
      log.debug("#{model}")
      begin
        model.send :include, PaperclipPathUpdate
        model.attachment_definitions.each do |d|
          file_type = "#{d.first}_file_name"
          if model.connection.select_all("select * from #{model.table_name} where #{file_type} is not NULL;").present?
            sub_path1 = sub_paths["#{model}"]
            sub_path2 = sub_paths_old["#{model}"]
            prefix = sub_path1.gsub("#{model.table_name}","#{model.table_name}_backup")
            prefix1 = sub_path2.gsub("#{model.table_name}","#{model.table_name}_backup")
            File.rename sub_path2, prefix1
            arr = Dir["#{prefix}/*/"].map {|a| File.basename(a) }
            arr.each do |arr_l|
              begin
                rec = model.find_without_school arr_l.to_i
                if rec.present? and rec[file_type].present?
                  file = "#{prefix}/#{arr_l}/original/#{rec[file_type]}"
                  if File.exists? file
                    unless rec.update_attribute(d.first.to_sym, File.open(file))
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
            sub_path3 = prefix1.gsub("#{model.table_name}_backup","#{model.table_name}_backup_done")
            File.rename "#{prefix1}", "#{sub_path3}"
            # BELOW 3 lines can delete backup folder after successful moving of files to new location
            #            if File.exists? prefix1
            #              FileUtils.rm_r prefix1
            #            end
          end
        end

      rescue Exception => e
        puts e
        puts "Failed to complete task! Reverting process"
        file = "uploads/#{model.table_name}"
        backup_file = "#{file}_backup"
        if File.exists? backup_file
          puts "Restoring old data of Discussion plugin"
          if File.exist? file
            FileUtils.rm_r file
          end
          File.rename "#{backup_file}","#{file}"
        end
      end
    end
  end
end  
