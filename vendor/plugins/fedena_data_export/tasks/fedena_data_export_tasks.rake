namespace :fedena_data_export do
  desc "Install Fedena Data Export Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_data_export/public ."
  end




  task :update_plugins_paths => :environment do
    models = [DataExport]
    sub_paths = {
      "DataExport" => "generated/data_exports"
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
            prefix = sub_path1.gsub("#{model.table_name}","#{model.table_name}_backup")
            File.rename sub_path1, prefix
            arr = Dir["#{prefix}/*/"].map {|a| File.basename(a) }
            arr.each do |arr_l|
              begin
                rec = model.find_without_school arr_l.to_i
                if rec.present? and rec[file_type].present?
                  file = "#{prefix}/#{arr_l}/#{rec[file_type]}"
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
            sub_path3 = prefix.gsub("#{model.table_name}_backup","#{model.table_name}_backup_done")
            File.rename "#{prefix}", "#{sub_path3}"
            # BELOW 3 lines can delete backup folder after successful moving of files to new location
            #            if File.exists? prefix1
            #              FileUtils.rm_r prefix1
            #            end
          end
        end

      rescue Exception => e
        puts e
        puts "Failed to complete task! Reverting process"
        file = sub_paths["#{model}"]
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
