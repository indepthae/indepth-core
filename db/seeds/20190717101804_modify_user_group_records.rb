require 'logger'
require 'fileutils'

log = Logger.new("log/user_group_#{Time.now.to_i}.log")

log.info("-----------------seed file started------#{Time.now}-----------------------")

#school_ids
MultiSchool.current_school = nil
schools_with_groups = UserGroup.find_by_sql("SELECT distinct school_id FROM `user_groups` WHERE school_id is not null;")

#updates school id in user_groups_users table
schools_with_groups.each do |school|
  MultiSchool.current_school = School.find(school.school_id)
  
  user_group_ids = UserGroup.all.collect(&:id)
  
  ActiveRecord::Base.connection.update("UPDATE user_groups_users 
                                        SET school_id = #{school.school_id} 
                                        WHERE user_group_id IN (#{user_group_ids.join(', ')})"
  ) if user_group_ids.present?
  
  log.info("-----------------updated school id #{school.school_id} for user_groups_user under #{user_group_ids.count} group ids-----------------------")

#modify records in user_groups_users table
 
#user counts
  total_user_count = {}
  total_user_count['parent'] = User.active.count(:joins=>:guardian_entry, :conditions=>{:parent=>true})
  total_user_count['student'] = User.active.count(:joins=>:student_entry, :conditions=>{:student=>true})
  total_user_count['employee'] = User.active.count(:joins=>:employee_entry,:conditions=>["employee = ? or admin = ?", true, true])
    
    
  UserGroup.all.each do |user_group|
    users_count_hash = { "student" => 0,  "parent" => 0, "employee" => 0}
    #-------------------start update records as per new structure for user user_groups_users---------------------------
    user_group_records = user_group.user_groups_users.all(:conditions=>{:target_type=>nil})
    user_group_records.each do |group_user_record|
      
      #user record
      invalid_record = true
      user_record = group_user_record.user
      
      if user_record.present?
    
        member_record, type = case true
                              when (user_record.student && user_record.student_entry.present?)
                                [user_record.student_entry, "student"]
                              when (user_record.parent && user_record.parent_record.present?)
                                [user_record.parent_record, "parent"]
                              when ((user_record.admin or user_record.employee) && user_record.employee_entry.present?)
                                [user_record.employee_entry, "employee"]
                              else
                                [nil, ""]
                              end
                      
        if member_record.present?
          group_user_record.user_id = member_record.user_id if type == "parent"
          group_user_record.member = member_record
          group_user_record.target_type = type
          group_user_record.save
          #count user count
          users_count_hash[type] += 1
          invalid_record = false
        end  
        
      end
      
      if invalid_record
        log.info("-----------------delete user_groups_users record------#{group_user_record.inspect}-----------------------")
        group_user_record.destroy
      end
      
    end
    #-------------------end update records as per new structure for user_groups_users---------------------------
    
    #-------------------start update records as per new structure for user group---------------------------
    user_group.reload
    all_members_hash = {}
    
    ['student', 'employee', 'parent'].each do |user_type|
      all_members_hash[user_type] = (users_count_hash[user_type].to_i == total_user_count[user_type].to_i)
    end
    
    user_group.all_members = all_members_hash
    user_group.save
    #-------------------end update records as per new structure for user group---------------------------
  end
  
end

log.info("-----------------seed file completed------#{Time.now}-----------------------")