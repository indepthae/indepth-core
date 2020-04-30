class CreatePrivilegeTags < ActiveRecord::Migration
  def self.up
    create_table :privilege_tags do |t|
      t.string :name_tag
      t.integer :priority

      t.timestamps
    end
    create_privilege_tag_and_update_privilege
  end

  def self.down
    drop_table :privilege_tags
  end

  def self.create_privilege_tag_and_update_privilege
    [
      {"name_tag" => "system_settings", "priority"=>5},
      {"name_tag" => "administration_operations", "priority"=>1},
      {"name_tag" => "academics", "priority"=>3},
      {"name_tag" => "student_management", "priority"=>2},
      {"name_tag" => "social_other_activity", "priority"=>4},
    ].each do |param|
      PrivilegeTag.find_or_create_by_name_tag(param)
    end


    #add privilege_tag_id, priority in privileges table
    #system_settings
    Privilege.reset_column_information
    system_settings_tag = PrivilegeTag.find_by_name_tag('system_settings')
    Privilege.find_by_name('GeneralSettings').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>10 )
    manage_course_batch=Privilege.find_by_name('ManageCourseBatch')
    add_new_batch=Privilege.find_by_name('AddNewBatch')
    if manage_course_batch.present?
      manage_course_batch.update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>20 )
    elsif add_new_batch.present?
      add_new_batch.update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>20 )
    end
    Privilege.find_by_name('SubjectMaster').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>30 )
    Privilege.find_by_name('SMSManagement').update_attributes(:privilege_tag_id=>system_settings_tag.id, :priority=>40 )


    #administration_operations
    administration_operations_tag = PrivilegeTag.find_by_name_tag('administration_operations')
    Privilege.find_by_name('HrBasics').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>50 )
    Privilege.find_by_name('EmployeeSearch').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>60 )
    Privilege.find_by_name('EmployeeAttendance').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>70 )
    Privilege.find_by_name('PayslipPowers').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>80 )
    Privilege.find_by_name('FinanceControl').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>90 )
    Privilege.find_by_name('EventManagement').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>100 )
    Privilege.find_by_name('ManageNews').update_attributes(:privilege_tag_id=>administration_operations_tag.id, :priority=>110 )
    #academics
    academics_tag = PrivilegeTag.find_by_name_tag('academics')
    Privilege.find_by_name('ExaminationControl').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>230 )
    Privilege.find_by_name('EnterResults').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>240 )
    Privilege.find_by_name('ViewResults').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>250 )
    Privilege.find_by_name('ManageTimetable').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>260 )
    Privilege.find_by_name('TimetableView').update_attributes(:privilege_tag_id=>academics_tag.id, :priority=>270 )
    #student_management
    student_management_tag = PrivilegeTag.find_by_name_tag('student_management')
    Privilege.find_by_name('Admission').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>280 )
    Privilege.find_by_name('StudentsControl').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>290 )
    Privilege.find_by_name('StudentView').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>300 )
    Privilege.find_by_name('StudentAttendanceRegister').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>310 )
    Privilege.find_by_name('StudentAttendanceView').update_attributes(:privilege_tag_id=>student_management_tag.id, :priority=>320 )
  end
  
end
