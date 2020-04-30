module MessageMod
  def all_recipients(user)
    permissions = get_message_permissions(user)
    case user.user_type
    when 'Admin'
      object_param = user.employee_record
    when 'Employee'
      object_param = user.employee_record
    when 'Student'
      object_param = user.student_record
    when 'Parent'
      object_param = Guardian.find_by_user_id(user.id).ward_id
    end
    fetch_allowed_recipients(permissions,user.user_type.downcase,object_param,user)
  end

  def fetch_allowed_recipients(permissions,type,object,user)
    user_ids = []
    if user.admin?
      user_ids += User.all(:conditions=>["id != ? AND is_deleted = ?",user.id,false]).collect(&:id)
    else
      if type == "employee" and permissions.include? "all_students"
        user_ids += employee_all_students(object).collect(&:user_id)
        permissions.reject! {|permission| permission == ('batch_students' || "subject_students")}
      end
      if type == "employee" and permissions.include? "all_parents"
        user_ids += employee_all_parents(object).collect(&:user_id)
        permissions.reject! {|permission| permission == ('parents_of_batch_students' || "parents_of_subject_students")}
      end
      if permissions.include? 'administrator'
        user_ids += all_admins.collect(&:id)
        permissions.reject! {|permission| permission == 'administrator'}
      end
      permissions.each do |permission|
        user_ids += send("#{type}_#{permission}",object).collect(&:user_id)
      end
    end
    return user_ids.compact.uniq
  end
  
  def all_admins(user = nil,query=nil)
    if query
       User.find(:all,
          :conditions => ["(ltrim(first_name) LIKE ?  OR ltrim(last_name) LIKE ?
            OR username LIKE ? OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? )) AND admin = ?",
            "%#{query}%", "%#{query}%",
            "%#{query}", "%#{query}",true])
    else
      User.admin
    end
  end
  
  def all_employees(user, dept_id = nil)
    dept_id = nil if dept_id == 'all'
    permissions = get_message_permissions(user)
    send("all_employees_for_#{user.user_type.downcase}",user,permissions, dept_id).uniq
  end
  
  def all_employees_for_student(user,permissions,dept_id = nil)
    employees = []
    student = user.student_record
    employees += student_subject_teachers(student,dept_id) if permissions.include? "subject_teachers"
    employees += student_batch_tutor(student,dept_id) if permissions.include? "batch_tutor"
    if permissions.include? "administrator"
      conditions = dept_id .present? ? ['employees.employee_department_id = ?',dept_id] : ""
      employee_admins = User.admin.all(:joins=>:employee_entry, :conditions=> conditions )
      employees << employee_admins.first.employee_entry if employee_admins.present?
      #employees << User.admin.all(:joins=>:employee_entry, :conditions=>"#{conditions}").first.employee_entry
    end
    return employees
  end
  
  def all_employees_for_parent(user,permissions,dept_id = nil)
    sibling_id = Guardian.find_by_user_id(user.id).ward_id
    employees = []
    if permissions.include? "administrator"
      employee_admins = User.admin.all(:joins=>:employee_entry)
      employees << employee_admins.first.employee_entry if employee_admins.present?
    end
    #employees << User.admin.all(:joins=>:employee_entry).first.employee_entry if permissions.include? "administrator"
    employees += parent_subject_teachers(sibling_id) if permissions.include? "subject_teachers"
    employees += parent_batch_tutor(sibling_id) if permissions.include? "batch_tutor"
    return employees
  end
  
  def all_employees_for_employee(user,permissions,dept_id = nil)
#    conditions = "employee_department_id = #{dept_id}" if dept_id
    conditions = dept_id.present? ? {:employee_department_id => dept_id} : {}
    employees = []
    employees += Employee.all(:include=>:user,:conditions=> conditions).sort_by{|a| a.full_name.downcase} if permissions.include? "all_employees"
    return employees
  end
  
  def all_employees_for_admin(user = nil,permissions = nil, dept_id = nil)
#    conditions = "employee_department_id = #{dept_id}" if dept_id
    conditions = dept_id.present? ? {:employee_department_id => dept_id} : {}
    Employee.all(:include=>:user,:conditions=> conditions).sort_by{|a| a.full_name.downcase}
  end
  
  #------------------students------------------#
  def all_students(user,batch_id = nil)
    batch_id = nil if batch_id == 'all'
    permissions = get_message_permissions(user)
    send("all_students_for_#{user.user_type.downcase}",user,permissions,batch_id).uniq
  end
  
  
  def all_students_for_student(user,permissions, batch_id = nil)
    students = []
    student = user.student_record
    students += student_batch_students(student) if permissions.include? "batch_students"
    return students
  end
  
  def all_students_for_employee(user,permissions,batch_id = nil)
    employee = user.employee_record
    students = []
    if permissions.include?("all_students")
      students += all_students_for_admin(nil,nil,batch_id)
    else
      students += employee_batch_students(employee,batch_id) if permissions.include?("batch_students")
      students += employee_subject_students(employee,batch_id) if permissions.include? "subject_students"
    end
    return students
  end
  
  def all_students_for_admin(user = nil,permissions = nil,batch_id = nil)
#    conditions = " AND batch_id = #{batch_id}" if batch_id
    conditions = batch_id.present? ? ['is_active = ? AND batch_id = ?', true, batch_id] : ['is_active = ?',true]
    Student.all(:conditions=> conditions)
  end
  
  def all_students_for_parent(user,permissions, batch_id = nil)
    []
  end
  
  #------------------Parents-----------------#
  
  def all_parents(user,batch_id = nil)
    batch_id = nil if batch_id == 'all'
    permissions = get_message_permissions(user)
    send("all_parents_for_#{user.user_type.downcase}",user,permissions,batch_id).uniq
  end
  
  def all_parents_for_employee(user,permissions,batch_id = nil)
    employee = user.employee_record
    student_parents = []
    if permissions.include?("all_parents")
      student_parents += all_parents_for_admin(nil,nil,batch_id)
    else
      student_parents += employee_parents_of_batch_students(employee,batch_id) if permissions.include?("parents_of_batch_students")
      student_parents += employee_parents_of_subject_students(employee,batch_id) if permissions.include?("parents_of_subject_students")
    end
    return student_parents
  end
  
  def all_parents_for_admin(user = nil,permissions = nil ,batch_id = nil)
#    conditions = "AND batch_id = #{batch_id}" if batch_id
    conditions = if batch_id.present?
      ["is_active = ? AND immediate_contact_id is NOT NULL AND batch_id = ?",true, batch_id]
    else
      ["is_active = ? AND immediate_contact_id is NOT NULL",true]
    end
    Student.all(:conditions=> conditions)
  end
  
  def all_parents_for_student(user,permissions,batch_id = nil)
    []
  end
  
  def all_parents_for_parent(user,permissions,batch_id = nil)
    []
  end

  #---------------------------------------------------------------------------#
  
  def employee_parents_of_subject_students(employee,batch_id = nil)
    student_parents = []
#    conditions = "batch_id = #{batch_id}" if batch_id
    conditions = batch_id.present? ? {:batch_id => batch_id} : {}
    employee.subjects.all(:conditions=> conditions ).each do |subject|
      student_parents += subject.fetch_students
    end
    student_parents.reject!{|student| student.immediate_contact_id.nil?}
    return student_parents
  end
  
  def employee_all_employees(employee)
    all_employees(employee.user)
  end
  
  def employee_all_students(employee)
    all_students(employee.user)
  end
  
  def employee_all_parents(employee)
    all_parents(employee.user)
  end
    
  def employee_batch_students(employee,batch_id=nil)
    students = []
#    conditions = "id = #{batch_id}" if batch_id
    conditions = batch_id.present? ? {:id => batch_id} : {}
    employee.batches.all(:conditions=> conditions).each do |batch|
      students += batch.students
    end
    return students
  end
  
  def employee_parents_of_batch_students(employee,batch_id = nil)
    students = employee_batch_students(employee,batch_id)
    students.reject {|student| student.immediate_contact_id.nil?}
  end
  
  def employee_subject_students(employee,batch_id = nil)
    students = []
#    conditions = "batch_id = #{batch_id}" if batch_id
    conditions = batch_id.present? ? {:batch_id => batch_id} : {}
    employee.subjects.all(:conditions=> conditions).each do |subject|
      students += subject.fetch_students
    end
    return students
  end
  
  def employee_administrator(employee)
    []
  end
  
  def student_batch_tutor(student,dept_id = nil)
#    conditions = "employee_department_id = #{dept_id}" if dept_id
    conditions = dept_id.present? ? {:employee_department_id => dept_id} : {}
    student.batch.employees.all(:include=>:user,:conditions=> conditions)
  end
  
  def student_batch_students(student)
    student.batch.students
  end
  
  def student_administrator(student = nil)
    employees = []
    employee_admins = User.admin.all(:joins=>:employee_entry)
    employees << employee_admins.first.employee_entry if employee_admins.present?
    #employees << User.admin.all(:joins=>:employee_entry).first.employee_entry
    return employees
  end
  
  def student_subject_teachers(student,dept_id = nil)
    employees = []
#    conditions = "employee_department_id = #{dept_id}" if dept_id
    conditions = dept_id.present? ? {:employee_department_id => dept_id} : {}
    student.subjects.all(:conditions=>{:is_deleted=>false},:include=>{:employees=>:user}).each do |subject|
      employees += subject.employees.all(:conditions=> conditions)
    end
    student.batch.subjects.all(:conditions=>["is_deleted = ? AND elective_group_id IS NULL",false],:include=>:employees).each do |subject|
      if subject.employees.present? and subject.batch_id==student.batch_id
        employees += subject.employees.all(:include=>:user, :conditions=> conditions)
      end
    end
    return employees
  end
  
  def parent_batch_tutor(sibling_id)
    batches = []
    employees = []
    Student.all(:conditions => {:sibling_id => sibling_id}, :include => {:batch => :employees}).each do |student|
      batches << student.batch
    end
    batches.each do |batch|
      batch.employees.each do |employee|
        employees << employee
      end
    end
    return employees
  end
  
  def parent_subject_teachers(sibling_id)
    subjects=[]
    normal_subjects=[]
    employees = []
    Student.all(:conditions => {:sibling_id => sibling_id}, :include => {:batch => :employees}).each do |student|
      subjects+=student.subjects.all(:include=>:employees, :joins=>:employees) if student.subjects.present?
      normal_subjects+=student.batch.subjects.all(:conditions=>["elective_group_id IS NULL"],:include => :employees,:joins=>:employees) if student.batch.subjects.present?
    end
    subjects.each do |subject|
      employees += subject.employees
    end
    normal_subjects.each do |subject|
      employees += subject.employees
    end
#    employees.uniq.map { |e| e.user.id if !e.user.nil? and e.user.id != user.id }
    return employees
  end
  
  def parent_administrator(sibling_id)
    employees = []
    employee_admins = User.admin.all(:joins=>:employee_entry)
    employees << employee_admins.first.employee_entry if employee_admins.present?
    #employees << User.admin.all(:joins=>:employee_entry).first.employee_entry
    return employees
  end
  
  def admin_all_parents(entry)
    all_parents_for_admin
  end
  
  def admin_all_employees(entry)
    all_employees_for_admin
  end
  
  def admin_all_students(entry)
    all_students_for_admin
  end
  
  def get_message_permissions(user)
    permissions = MessageSetting.get_permissions(user.user_type.downcase)
    permissions.config_value || []
  end
end