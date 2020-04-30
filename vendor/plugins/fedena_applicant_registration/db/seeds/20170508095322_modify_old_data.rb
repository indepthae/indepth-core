schools = School.all
schools.each do|school|
  puts "Started working on school #{school.id}============================================================================"
  MultiSchool.current_school = school
  if FedenaPlugin.can_access_plugin? "fedena_audit"
    FedenaAudit.disable_audit = true
  end
  default_statuses = ApplicationStatus.all
  if default_statuses.empty?
    puts "creating default application statuses============================================================================"
    default_statuses = ApplicationStatus.create_defaults_and_return
  end
  RegistrationCourse.all.each do|reg_course|
    puts "Started working on registration course #{reg_course.id}=================================================================="
    default_form =  Marshal.load(Marshal.dump(ApplicationSection::DEFAULT_FORM))
    has_modifications = false
    section_order = 8
    
    #    Student additional details
    
    if reg_course.include_additional_details == true
      puts "Started modifying student additional fields for reg course #{reg_course.id}================================================"
      st_addl_fields = StudentAdditionalField.find(:all,:conditions=>["id in (?) or (is_mandatory=true and status=true)", reg_course.additional_field_ids],:order=>"priority ASC")
      if st_addl_fields.present?
        additional_group = ApplicantAddlFieldGroup.find_or_create_by_name(:name=>I18n.t('additional_detail'), :registration_course_id=>nil, :is_active=>true)
        section_order = section_order + 1
        section_hash = {:section_name=>"",:applicant_addl_field_group_id=>additional_group.id,:section_order=>section_order,:section_description=>"",:fields=>[]}
        field_order = 1
        st_addl_fields.each do|st_addl_field|
          puts "Modifying student addl field #{st_addl_field.id}================================"
          ApplicantStudentAddlField.create(:registration_course_id=>reg_course.id,:student_additional_field_id=>st_addl_field.id,:applicant_addl_field_group_id=>additional_group.id)
          section_hash[:fields] << {:field_type=>"student_additional",:show_field=>st_addl_field.status,:field_name=>st_addl_field.id,:mandatory=>(st_addl_field.is_mandatory == true ? "default_true" : false),:field_order=>field_order}
          field_order = field_order + 1
        end
        default_form << section_hash
        puts "pushed hash for student addl fields =============================================================="
        has_modifications = true
      end
      puts "finished modifying student additional fields for reg course #{reg_course.id}================================================"
    end
    
    #    Applicant Additional Details
    
    addl_field_groups = reg_course.applicant_addl_field_groups.all(:order=>"position ASC",:include=>:applicant_addl_fields)
    if addl_field_groups.present?
      puts "Started modifying applicant addl fields for reg course #{reg_course.id}=================================================="
      addl_field_groups.each do|addl_field_group|
        puts "modifying field group #{addl_field_group.id}==================================================="
        section_order = section_order + 1
        addl_section_hash = {:section_name=>"",:applicant_addl_field_group_id=>addl_field_group.id,:section_order=>section_order,:section_description=>"",:fields=>[]}
        field_order = 1
        field_type_mapping = {:text=>"singleline",:belongs_to=>"single_select",:has_many=>"multi_select"}
        addl_field_group.applicant_addl_fields.all(:order=>"position ASC").each do|addl_field|
          puts "modifying addl field #{addl_field.id}======================================================================="
          addl_field.field_type = field_type_mapping[addl_field.field_type.to_sym]
          addl_field.record_type = "alpha"
          addl_field.send(:update_without_callbacks)
          addl_section_hash[:fields] << {:field_type=>"applicant_additional",:show_field=>(addl_field_group.is_active==true ? addl_field.is_active : false),:field_name=>addl_field.id,:mandatory=>addl_field.is_mandatory,:field_order=>field_order}
          field_order = field_order + 1
        end
        default_form << addl_section_hash
        puts "pushed hash for applicant addl fields =============================================================="
        has_modifications = true
      end
      puts "completed modifying applicant addl fields for reg course #{reg_course.id}================================================"      
    end
    
    #    Applicant along with attachments
    
    attachment_section = default_form.find{|as| as[:section_name] == "attachments"}
    course_applicants = reg_course.applicants.all(:include=>:applicant_addl_attachments)
    attachment_field_order = 1
    course_applicants.each do|applicant|
      applicant.status = default_statuses.find_by_name(applicant.status).id
      if applicant.send(:update_without_callbacks)
        puts "updated applicant #{applicant.id}=================================================================================="
      else
        puts "Failed to update applicant #{applicant.id}.. Errors : #{applicant.errors.full_messages.join(', ')}=============================="
      end
      applicant.applicant_addl_attachments.each_with_index do|addl_attachment,i|
        att_field = ApplicantAddlAttachmentField.find_by_name_and_registration_course_id("Attachment #{i+1}",reg_course.id)
        unless att_field.present?
          att_field = ApplicantAddlAttachmentField.create(:name=>"Attachment #{i+1}",:registration_course_id=>reg_course.id)
          puts "created attachment field #{att_field.name} for reg course #{reg_course.id}================================"
        end
        unless attachment_section[:fields].find{|at| at[:field_name]==att_field.id}.present?
          att_hash = {:field_type=>"applicant_attachment",:show_field=>true,:field_name=>att_field.id,:mandatory=>false,:field_order=>attachment_field_order}          
          attachment_section[:fields] << att_hash      
          attachment_field_order = attachment_field_order + 1
          has_modifications = true
        end
        addl_attachment.applicant_addl_attachment_field_id = att_field.id
        if addl_attachment.send(:update_without_callbacks)
          puts "updated attachment #{addl_attachment.id}============================="
        else
          puts "could not update attachment #{addl_attachment.id}.. Errors : #{addl_attachment.errors.full_messages.join(', ')}========================="
        end
      end
    end
    if has_modifications == true
      app_form = ApplicationSection.new(:registration_course_id=>reg_course.id,:guardian_count=>1,:section_fields=>default_form)
      if app_form.send(:create_without_callbacks)
        puts "saved form for reg course #{reg_course.id}========================"
      else
        puts "couldn't save form for reg course #{reg_course.id}.. Errors : #{reg_course.errors.full_messages.join(', ')}========================"
      end
    end
    puts "Completed modifications for reg course #{reg_course.id}==============================================="
  end
  if FedenaPlugin.can_access_plugin? "fedena_audit"
    FedenaAudit.disable_audit = nil
  end
  puts "Completed modifications for school #{school.id}======================================================"
end