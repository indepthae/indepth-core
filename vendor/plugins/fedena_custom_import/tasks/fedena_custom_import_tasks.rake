namespace :fedena_custom_import do
  desc "Install Fedena Data Import Module"
  task :install do
    system "rsync --exclude=.svn -ruv vendor/plugins/fedena_custom_import/public ."
  end

  desc "Copy Fedena Data import files from public to uploads"
  task :public_to_uploads => :environment do
    m = 'imports'
    model_name = m.classify.constantize
    table_name = m
    if model_name.attachment_definitions.present?
      model_name.attachment_definitions.each do |attachment|
        attachment_name = attachment.first.to_s
        conditions = []
        conditions << "#{attachment_name}_file_name is not NULL"
        begin
          conditions << "school_id is not NULL" if MultiSchool.multi_school_models.include? m.classify
        rescue
        end

        sql = "select * from #{table_name} where #{conditions.join(" and ")}"
        all_records = ActiveRecord::Base.connection.execute(sql).all_hashes
        all_records.each do |rec|
          if rec.keys.include?("school_id") && defined? MultiSchool
            MultiSchool.current_school = School.find rec["school_id"] unless rec["school_id"] == MultiSchool.current_school.try(:id)
          end
          file_name_path = rec['csv_file_file_name']
          file_name = File.basename(file_name_path)
          rec['csv_file_file_name'] = file_name
          record = model_name.send(:instantiate, rec)
          rec_id = rec['id']
          ac_record = model_name.find(rec_id)
          ac_record.update_attribute(:csv_file_file_name, file_name)
          if record['status'].blank?
            attachment_new_path = record.send("#{attachment_name}").path

            attachment_old_path = "#{RAILS_ROOT}/public/csv_file/" + rec_id + "/" + file_name
            if File.exist?("#{attachment_old_path}")
              new_attachment_dir_path = attachment_new_path.gsub(file_name, '')
              FileUtils.mkdir_p(new_attachment_dir_path)
              FileUtils.cp(attachment_old_path, new_attachment_dir_path)
            end
          end
        end
      end
    end
  end
end