class MessageSetting < ActiveRecord::Base
  xss_terminate# :sanitize => [:config_value]
  serialize :config_value, Array
  
  include MessageMod
  extend MessageMod
  
  class << self
    def get_permissions(type)
      type = 'administrator' if type == 'admin'
      unless all.present?
        initialize_settings
      end
      find_or_create_by_config_key("#{type}_permissions")
    end
    
    def initialize_settings
      create(:config_key=>'employee_permissions',:config_value=>["parents_of_subject_students", "all_employees","all_parents", "batch_students", "parents_of_batch_students", "subject_students","all_students","administrator"])
      create(:config_key=>'student_permissions',:config_value=>["batch_tutor", "administrator"])
      create(:config_key=>'parent_permissions',:config_value=>["batch_tutor", "subject_teachers", "administrator"])
      create(:config_key=>'administrator_permissions',:config_value=>["all_parents", "all_employees", "all_students"])
    end
    
    def update_permissions(hash)
      hash.each do |key,value|
        find_by_config_key(key.to_s).update_attributes(:config_value=>value)
      end
    end
    
    def can_message?(user)
      return false if all_recipients(user).blank?
      if user.user_type == 'Admin'
        return true
      else
        find_by_config_key("#{user.user_type}_permissions").try(:config_value).present?
      end
    end
    
    def can_reply?(recipient_id,thread_id,user)
      thread = MessageThread.find thread_id
      if !thread.can_reply? and thread.creator_id != user.id
        return false
      else
        recp_user = User.find recipient_id
        if recp_user.parent?
          students = all_parents(user)
          parent_ids = students.collect(&:immediate_contact_id)
          ids = Guardian.all(:conditions=>{:id=>parent_ids}).collect(&:user_id)
          ids.include? recipient_id.to_i
        else
          all_recipients(user).include? recipient_id.to_i
        end
      end
    end
    
    def search_recipients(query,current_user)
        user = current_user
        student_user_ids = MessageThread.get_students('all',user)
        parent_user_ids = MessageThread.get_parents('all',user)
        employee_user_ids = MessageThread.get_employees('all',user)
        permissions = get_message_permissions(user)
        admin_users = (permissions.include? "administrator" or user.admin?) ? all_admins(user,query) : []
        admin_users.reject! {|admin| admin.id == user.id || (employee_user_ids.include? admin.id) }
        students = []
        employees = []
        students += Student.find(:all,
          :conditions => ["(ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                              OR admission_no = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ))
                              AND user_id in (?)",
            "%#{query}%", "%#{query}%", "%#{query}%",
            "#{query}", "%#{query}", student_user_ids+parent_user_ids],
          :order => "#{Student.check_and_sort}",:include=>"batch") unless query == ''
          employees += Employee.find(:all,
            :conditions => ["(ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR employee_number = ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? )
                            OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ))
                             AND user_id in (?)",
              "#{query}%","#{query}%","#{query}%",
              "#{query}", "#{query}%", "#{query}%", employee_user_ids],
            :order => "employee_department_id asc,first_name asc",:include=>"employee_department") unless query == ''
        return students,employees,admin_users
    end

  end
end