module IndepthOverrides
  module IndepthArchivedStudentModel
  	def self.included (base)
  		base.instance_eval do
        
        def archived_student_revert(archived_student_id)
          student=Student.new
          ActiveRecord::Base.transaction do
            archived_student = ArchivedStudent.find archived_student_id
            old_id = archived_student.former_id.to_s.dup
            has_paid_fees=archived_student.former_has_paid_fees.to_s.dup
            has_paid_fees_for_batch=archived_student.former_has_paid_fees_for_batch.to_s.dup
            archived_student_attributes = archived_student.attributes
            archived_student_attributes.delete "id"
            archived_student_attributes.delete "former_id"
            archived_student_attributes.delete "status_description"
            archived_student_attributes.delete "date_of_leaving"
            archived_student_attributes.delete "former_has_paid_fees"
            archived_student_attributes.delete "former_has_paid_fees_for_batch"
            archived_student_attributes.delete "created_at"
            archived_student_attributes.delete "roll_number"
            sibling_id=archived_student_attributes["sibling_id"].present? ? archived_student_attributes["sibling_id"] : old_id
            student = Student.new(archived_student_attributes)
            student.has_paid_fees=has_paid_fees
            student.has_paid_fees_for_batch=has_paid_fees_for_batch
            unless archived_student.familyid.present?
              student.revert_mode = 'Archival'
            end
            if student.save
              sib_stud=Student.find_by_id(sibling_id)
              unless sib_stud.present?
                sibling_id=old_id
              end
              sql = "update students set id = #{old_id},sibling_id = #{sibling_id} where id = #{student.id}"
              ActiveRecord::Base.connection.execute(sql)
              student=Student.find(old_id)
              student.photo = archived_student.photo if archived_student.photo.file?
              student.save
              student.batch.activate
              student.batch.course.activate
              if student.all_siblings.present?
                unless student.immediate_contact.present? and student.immediate_contact.user.present?
                  student.immediate_contact_id=nil
                  student.save
                end
              else
                archived_guardians=archived_student.archived_guardians
                archived_guardians.each do |a_g|
                  former_user_id = a_g.attributes["former_user_id"].to_s.dup
                  former_id=a_g.attributes["former_id"].to_s.dup
                  archived_guardian_attributes = a_g.attributes
                  archived_guardian_attributes.delete "former_user_id"
                  archived_guardian_attributes.delete "former_id"
                  archived_guardian_attributes.delete "id"
                  guardian = Guardian.new(archived_guardian_attributes)
                  guardian.user_id=former_user_id
                  if guardian.save
                    a_g.destroy
                  end
                  if student.immediate_contact_id.to_s==former_id
                    student.immediate_contact_id=guardian.id
                    student.save
                  end
                end
              end
              archived_student.destroy
            else
              raise ActiveRecord::Rollback
            end
          end
          return student
        end
	  	end
  	end
    
  end
end

    