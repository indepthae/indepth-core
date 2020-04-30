class UserAdditionalDetails
  
  def initialize(users, type, all_active)
    @users = users
    @type = type
    @all_active = all_active
  end
  
  def fetch_additional_details
    fetch_users
    fetch_all_details
  end
  
  def fetch_users
    if @all_active
      present_user_ids = @users
    else
      present_user_ids = @users.select{|u| u.current_type != 'archived'}.collect(&:id)
      archived_user_ids = @users.select{|u| u.current_type == 'archived'}.collect(&:id)
    end

    case @type
    when 'Student'
      @all_users = Student.all(:select =>"id, 'present' AS current_type, sibling_id, immediate_contact_id, phone2", 
        :include => [{:student_additional_details => :student_additional_field}, :guardians], 
        :conditions  => {:id => present_user_ids})
      @all_users += ArchivedStudent.all(:select =>"id, former_id, 'archived' AS current_type, sibling_id, immediate_contact_id, phone2", 
        :include => [{:student_additional_details => :student_additional_field}, :archived_guardians], 
        :conditions  => {:former_id => archived_user_ids}) unless @all_active
    when 'Employee'
      @all_users = Employee.all(:select => "id, 'present' AS current_type", 
        :include => {:employee_additional_details => :additional_field}, 
        :conditions  => {:id => present_user_ids})
      @all_users += ArchivedEmployee.all(:select => "id, former_id, 'archived' AS current_type", 
        :include => {:archived_employee_additional_details => :additional_field}, 
        :conditions  => {:former_id => archived_user_ids}) unless @all_active
    end
  end
  
  def fetch_all_details
    additional_details_hsh = {}
    @all_users.each do |user|
      user_hsh = get_additional_details(user)
      if @type == 'Student'
        user_hsh.merge!({
            :student_mobile_phone => user.phone2,
            :immediate_contact_first_name => user.ef_immediate_contact.try(:first_name),
            :immediate_contact_mobile_phone => user.ef_immediate_contact.try(:mobile_phone),
            :father_first_name => user.ef_father.try(:first_name),
            :father_mobile_phone => user.ef_father.try(:mobile_phone),
            :mother_first_name => user.ef_mother.try(:first_name),
            :mother_mobile_phone => user.ef_mother.try(:mobile_phone)
          })
      end
      user_id = (user.current_type == 'archived' ? user.former_id : user.id)
      additional_details_hsh[user_id] = user_hsh
    end
    additional_details_hsh
  end
    
  def get_additional_details(user)
    assoc = fetch_additional_assoc(user)
    field_assoc = fetch_field_assoc
    additional_details_hsh = {}
    active_details = user.send(assoc).select{|ad| ad.send(field_assoc).try(:status)}
    active_details.each do |detail|
      field = detail.send(field_assoc)
      name = ((field.try(:name)||"").downcase.gsub(" ","_") + "_additional_fields_" + detail.additional_field_id.to_s).to_sym
      additional_details_hsh[name] = detail.additional_info
    end
    additional_details_hsh
  end
    
  def fetch_additional_assoc(user)
    case @type
    when "Student", "ArchivedStudent"
      "student_additional_details"
    when "Employee"
      (user.current_type == "archived" ? "archived_employee_additional_details" : "employee_additional_details" )
    end
  end
  
  def fetch_field_assoc
    (@type == 'Student' ? "student_additional_field" : "additional_field")
  end
  
end

