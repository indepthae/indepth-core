class UserGroup < ActiveRecord::Base
  has_many :user_groups_users
  has_many :users, :through => :user_groups_users
  
  serialize :all_members, Hash

  validates_presence_of :name
  validates_uniqueness_of :name
  before_destroy :confirm_group_is_empty

  class << self
    def get_students(batch_id)
      students=Batch.find(batch_id).students.sort_by{|a| a.full_name.downcase}
      user_ids=students.collect(&:user_id)
      user_ids.compact.uniq
    end

    def get_employees dept_id
      employees=EmployeeDepartment.find(dept_id).employees.sort_by{|a| a.full_name.downcase}
      user_ids=employees.collect(&:user_id)
      user_ids.compact.uniq
    end

    def get_parents batch_id
      user_ids=Student.all(:conditions=> ["immediate_contact_id is NOT NULL AND batch_id = ?", batch_id]).sort_by{|a| a.full_name.downcase}.collect(&:user_id)
      user_ids.compact.uniq
    end

    def get_departments_batches_and_parents
      employee_departments = find_employee_departments
      batches = find_batch
      return employee_departments, batches, batches
    end

    def find_employee_departments
      EmployeeDepartment.active
    end

    def find_batch
      Batch.active
    end

    def to_integer_array(string)
      string.to_s.split(',').map { |char| char.to_i}
    end
    
    def add_members(group_id, student_ids, employee_ids, parent_ids)
      group = find(group_id)
      add_all_members(group, student_ids=="all", employee_ids == "all", parent_ids == "all") 
      
      user_id_hash = {"student" => student_ids, "employee" => employee_ids, "parent" => parent_ids}
      populate_user_group(group, user_id_hash)
      
      group.update_attributes(:status => false)
    end
    
    def populate_user_group(group, user_id_hash, method_type = false)
      if method_type
        user_id_hash.each_pair{|k,v| update_if_not_all(group, v, k)}
      else
        user_id_hash.each_pair{|k,v| add_if_not_all(group, v, k)}
      end        
    end  
    
    def add_if_not_all(group, ids, type)
      if ids != "all"
        ids = to_integer_array(ids)
        add_to_groups(group , ids, type) if ids.present?
      end  
    end  
    
    def add_all_members(group, stu, emp, parent)
      member_hash = { 'student' => stu, 'employee' => emp, 'parent' => parent }
      group.all_members = member_hash
      group.save
    end
        
    def add_to_groups(group, ids, type)
      ids.each do |id|
        user_record=User.fetch_user_record(id, type)
        user_groups_user = UserGroupsUser.create(:user_id => id, :user_group_id => group.id, :member => user_record, :target_type => type)
      end
      
    end    
    
    def update_members(group_id, student_ids, employee_ids, parent_ids)
      group = find(group_id)
      add_all_members(group, student_ids=="all", employee_ids == "all", parent_ids == "all")
      
      user_id_hash = {"student" => student_ids, "employee" => employee_ids, "parent" => parent_ids}
      populate_user_group(group, user_id_hash, true)
      
      group.update_attributes(:status => false)
    end
    
    def update_if_not_all(group, ids, type)
      if ids == "all" || ids == ""
        UserGroupsUser.destroy_all(["user_group_id=(?) and target_type=(?)", group.id, type])
      else
        ids = to_integer_array(ids)
        delete_users(group, ids, type)
        find_or_create_member(group.id , ids, type) if ids.present?
      end    
    end  
    
    def delete_users(group, ids, type)
      ids_to_delete = group.user_groups_users.all(:conditions => ["user_id NOT IN (?) and target_type = ?", ids, type]).map(&:user_id)
      UserGroupsUser.destroy_all(["user_id IN (?) and user_group_id=? and target_type=?", ids_to_delete, group.id, type])
    end  
    
    
    def find_or_create_member(group_id, user_ids, m_type)
      user_ids.each do |user_id|
        user_groups_user = UserGroupsUser.find_or_create_by_user_group_id_and_user_id_and_target_type(group_id, user_id, m_type)
        if(user_groups_user.present? and !user_groups_user.member.present?)    
          user_record=User.fetch_user_record(user_id, m_type)
          user_groups_user.update_attributes(:member => user_record)
        end  
      end  
    end
    
  end
  
  def delete_all(type)
    hash = self.all_members
    hash[type] = false
    self.update_attributes(:all_members => hash)
    # self.user_groups_users.all(:conditions => { :target_type => type }).map{|x| x.destroy} unless self.user_groups_users.present?
  end  

  def find_users(type)
    hash = Hash.new
    if all_members[type]
      hash = {type => ["all"]}
    else
      user_ids = self.user_groups_users.all(:conditions => ["target_type = ?", type]).map(&:user_id)
      hash = {type => user_ids}
    end     
    return hash 
  end

  def confirm_group_is_empty
    !self.user_groups_users.exists? && !self.all_members["student"] &&  !self.all_members["employee"] && !self.all_members["parent"]
  end
  
  def fetch_users_list
    user_hash = { "student"=>[], "employee"=>[], "parent"=>[] }
    user_hash['employee'] = all_members['employee'] ? [true] : []
    user_hash['student'] =  all_members['student'] ? [true] : []
    user_hash['parent'] = all_members['parent'] ? [true] : []
    user_groups_users.map{|user| user_hash[user.target_type] << user.user_id}  if all_members.values.include?(false)
    user_list = []
    user_hash.each_pair do |k,v|
      user_ids = v.flatten.uniq
      if user_ids.include?(true)
        user_list << {"id" => "all_#{k}" , "value" => "All #{k}","child_count"=>0}
      else  
        user_list << user_ids.map{|uid| {"id"=>uid ,"value"=>"#{user_record(uid).user_full_name} (#{k})" ,"child_count"=>0} if user_record(uid).present?  } if user_ids.present?
      end
    end
    user_list = user_list.flatten
    user_list = user_list.present? ? user_list.sort_by{|u| u["value"].downcase} : user_list
    return user_list
  end
  
  def fetch_recipients_lists(selected_ids)
    group_users = []
    group_users = UserGroupsUser.find_all_by_user_group_id_and_user_id(id,selected_ids ) if all_members.values.include?(false)
    student_parents_user_ids = group_users.select{|x| x.target_type == 'parent'}.collect(&:user_id)
    guardian_sids = Student.find_all_by_user_id(student_parents_user_ids).collect(&:id)
    guardian_sids = (guardian_sids << 'all_parent' ) if selected_ids.include?('all_parent')
    user_ids = group_users.reject{|x| x.target_type == 'parent'}.collect(&:user_id)
    users = User.all(:include=>[:employee_entry, :student_entry], :conditions=>["id in (?)",user_ids])
    student_users = users.select{|u| u.student == true}
    employee_users =  users.select{|u| u.employee == true}
    student_ids = student_users.collect{|u| u.student_entry.id }
    student_ids = (student_ids << 'all_student' ) if selected_ids.include?('all_student')
    employee_ids = employee_users.collect{|u| u.employee_entry.id }
    employee_ids = (employee_ids << 'all_employee' ) if selected_ids.include?('all_employee')
    return {:student_ids => student_ids, :employee_ids => employee_ids , :guardian_sids => guardian_sids} 
  end
  
  
  private
  
  def user_record(uid)
    User.first(:conditions=> {:id => uid, :is_deleted => false})
  end
    
end
