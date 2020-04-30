namespace :fedena do  
  namespace :fix do 
    task :applicant_attachments => :environment do
      if (MultiSchool rescue nil)
        School.find_in_batches(:batch_size => 500) do |schools|
          #        puts schools.length
          schools.each do |school|          
            puts "Checking for school id #{school.id}"
            MultiSchool.current_school = school
            if (ApplicantAddlAttachment rescue nil)
              cnt = 0
              ApplicantAddlAttachment.find_in_batches(:batch_size => 500, :conditions => "
            attachment_file_name is not null", :include => :applicant) do |applicant_attachments|
                cnt += 1
                puts "Total Applicant Additional Attachments in School##{school.id} is #{applicant_attachments.length} for pass##{cnt}"              
                applicant_attachments.each do |applicant_attachment|
                  attachment = applicant_attachment.attachment
                  attachment_path = attachment.path
                  applicant = applicant_attachment.applicant
                  unless attachment.exists?
                    puts "Applicant Attachment ##{applicant_attachment.id} has either no attachment or attachment is unlinked"
                    s3_search_cmd = "aws s3api list-objects --bucket #{Config.bucket_private} --prefix \"uploads/#{school.id}/applicant_addl_attachments/attachments/#{applicant_attachment.id}/original\""
                    begin               
                      response = `#{s3_search_cmd}`                      
                      if response.present?
                        resp_hsh = JSON.parse response
                        s3_existing_path = resp_hsh["Contents"].first["Key"]
                        unless s3_existing_path == attachment_path
                          res1 = AWS::S3::S3Object.rename s3_existing_path, attachment_path, Config.bucket_private  
                          begin
                            if res1.response.code == "200"
                              student_attachments = StudentAttachment.all(:conditions => {
#                                  :batch_id => applicant_attachment.applicant.batch_id, 
                                  :attachment_file_name => applicant_attachment.attachment_file_name, 
                                  :attachment_content_type => applicant_attachment.attachment_content_type, 
                                  :attachment_file_size => applicant_attachment.attachment_file_size},
                                  :include => :student)
                              if student_attachments.present? 
                                student_attachments.each do |student_attachment|                                  
                                  unless student_attachment.attachment.exists?
                                    student = student_attachment.student
                                    student = ArchivedStudent.find_by_former_id(student_attachment.student_id) unless student.present?
                                    if applicant.first_name == student.first_name and ((!applicant.middle_name.present? and student.middle_name == '') || (applicant.middle_name.present? and applicant.middle_name == student.middle_name)) and ((!applicant.last_name.present? and student.last_name == '') || (applicant.last_name.present? and applicant.last_name == student.last_name))
                                      if (applicant.batch_id.present? and applicant.batch_id == student.batch_id) or !(applicant.batch_id.present?)
                                        puts "Student Attachment ##{student_attachment.id} has no attachment present or is unlinked"
                                        res2 = AWS::S3::S3Object.copy attachment_path, student_attachment.attachment.path, Config.bucket_private                                                  
                                        puts "Failed to copy student attachment for student attachment ##{student_attachment.id}" unless res2.response.code == "200"                                                                                                              
                                      end
                                    end
                                  end                                  
                                end
                              end
                            else
                              puts "Failed to update attachment for applicant_additional_attachment ##{applicant_attachment.id}"
                            end
                          rescue
                            puts res1.inspect
                          end                          
                        end                        
                      else
                        puts "no attachment was found with pattern for applicant additional attachment ##{applicant_attachment.id}"
                      end                        
                    end
                  else
                    puts "Applicant attachment ##{applicant_attachment.id} is present. Checking for student attachment if present and need to fix : #{applicant_attachment.id}"
                    applicant = applicant_attachment.applicant                    
                    student_attachments = StudentAttachment.all(:conditions => {
#                        :batch_id => applicant_attachment.applicant.batch_id, 
                        :attachment_file_name => applicant_attachment.attachment_file_name, 
                        :attachment_content_type => applicant_attachment.attachment_content_type, 
                        :attachment_file_size => applicant_attachment.attachment_file_size})
                    if student_attachments.present?
                      student_attachments.each do |student_attachment|                                  
                        unless student_attachment.attachment.exists?
                          student = student_attachment.student
                          student = ArchivedStudent.find_by_former_id(student_attachment.student_id) unless student.present?
                          if applicant.first_name == student.first_name and 
                              ((!applicant.middle_name.present? and student.middle_name == '') || 
                                (applicant.middle_name.present? and applicant.middle_name == student.middle_name)) and 
                              ((!applicant.last_name.present? and student.last_name == '') || 
                                (applicant.last_name.present? and applicant.last_name == student.last_name))
                            if (applicant.batch_id.present? and applicant.batch_id == student.batch_id) or !(applicant.batch_id.present?)
                              puts "Student Attachment ##{student_attachment.id} has no attachment present or is unlinked"
                              res2 = AWS::S3::S3Object.copy attachment_path, student_attachment.attachment.path, Config.bucket_private                                                  
                              puts "Failed to copy student attachment for student attachment ##{student_attachment.id}" unless res2.response.code == "200"                                                                                                              
                            end
                          end
                        end                                  
                      end
                    end
                  end
                  #                end              
                end
              end
            end
          end
        end
      else
        puts "not multischool"
      end
    end
  end
end