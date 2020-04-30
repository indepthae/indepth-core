require 'fileutils'
require 'logger'
unless (StudentAddlAttachment rescue false)
  log = Logger.new('log/student_addl_attachment_seed_operation.log')
  student_addl_attachments = RecordUpdate.connection.execute("SELECT * FROM student_addl_attachments").all_hashes
  if student_addl_attachments.present?
    school_ids = student_addl_attachments.map {|x| x['school_id'].to_i }.uniq
    student_ids = student_addl_attachments.map {|x| x['student_id'].to_i }.uniq
    student_batch_ids = Hash.new
    RecordUpdate.connection.execute("SELECT id, batch_id FROM students where id in (#{student_ids.join(',')})").all_hashes.map {|x| student_batch_ids[x['id'].to_i] = x['batch_id'].to_i }
    user_ids = RecordUpdate.connection.execute("SELECT * FROM users where admin = 1 and school_id in (#{school_ids.join(',')})").all_hashes.group_by{|x| x['school_id'] }.map {|x,y| { x => y.first['id']}}
    schools = School.find_all_by_id(school_ids)
    school_student_addl_attachments = student_addl_attachments.group_by {|x| x['school_id']}  
    schools.each do |school|  
      MultiSchool.current_school = school
      current_student_addl_attachments = school_student_addl_attachments["#{school.id}"]
      if current_student_addl_attachments.present?
        current_student_addl_attachments.each do |attachment_attributes|     
          student_attachment = StudentAddlAttachment.send :instantiate, attachment_attributes
          file_path = student_attachment.attachment.path
          if File.exist?(file_path) # attachment file is present
            log.info("===============================================")
            log.info("Moving StudentAddlAttachment record id##{student_attachment.id} to student attachment")
            document = StudentAttachment.new(attachment_attributes)
            document.attachment = student_attachment.attachment
            document.uploader_id = user_ids[school.id] if user_ids.present?
            document.attachment_name = attachment_attributes['attachment_file_name']
            document.batch_id = student_batch_ids[document.student_id]
            document.is_registered = 1
            document.save
            unless document.errors.present?
              FileUtils.mkdir_p file_path.gsub(document.attachment_name,'')
              FileUtils.cp(file_path,document.attachment.path)
              log.info("Moved successfully to StudentAttachment record id##{document.id}")
              log.info("===============================================")
            else
              log.info("===============================================")
              log.info("Failed to move StudentAddlAttachment record id##{student_attachment.id}, errors occured :: #{document.errors.full_messages.join(',')}")
              log.info("===============================================")          
            end
          else # attachment file is present
            log.info("===============================================")
            log.info("File is not found for StudentAddlAttachment record id##{student_attachment.id}")
            log.info("===============================================")
          end
        end    
      end
    end
  end
end