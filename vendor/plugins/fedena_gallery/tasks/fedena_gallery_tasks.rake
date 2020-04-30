namespace :fedena_gallery do
  desc "Install Fedena Photo Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_gallery/public ."
  end


  desc "Update Paths for Photo Module"
  task :update_plugins_paths => :environment do

    model = GalleryPhoto
    sub_path = "uploads/gallery_photos/photos"
    sub_path_old = "uploads/gallery_photos"

    log = Logger.new("log/paperclip_path_update.log")
    log.debug("#{model}")
    begin
      #      models.each do |model|

      model.send :include, PaperclipPathUpdate
      model.attachment_definitions.each do |d|
        file_type = "#{d.first}_file_name"
        if model.connection.select_all("select * from #{model.table_name} where #{file_type} is not NULL;").present?
          #sub_path1 = sub_paths["#{model}"]
          prefix = sub_path.gsub("#{model.table_name}","#{model.table_name}_backup")
          prefix1 = sub_path_old.gsub("#{model.table_name}","#{model.table_name}_backup")
          File.rename sub_path_old, prefix1
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
          sub_path2 = prefix1.gsub("#{model.table_name}_backup","#{model.table_name}_backup_done")
          File.rename "#{prefix1}", "#{sub_path2}"
          # BELOW 3 lines can delete backup folder after successful moving of files to new location
          #            if File.exists? prefix1
          #              FileUtils.rm_r prefix1
          #            end
        end
      end
      #      end
    rescue Exception => e
      log.debug("#{e.message}")
      log.debug("------------")
      log.debug("#{e.backtrace.inspect}")
      puts e
      puts "Failed to complete task! Reverting process"
      #      models.each do |model|
      file = "uploads/#{model.table_name}"
      backup_file = "#{file}_backup"
      if File.exists? backup_file
        puts "Restoring old data of Discussion plugin"
        if File.exist? file
          FileUtils.rm_r file
        end
        File.rename "#{backup_file}","#{file}"
      end
      #      end
    end

  end

end
