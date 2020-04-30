class AssignableFolder < Folder
  attr_accessor :category
  has_and_belongs_to_many :categories, :class_name => "FolderAssignmentType"
  validates_uniqueness_of :name
  belongs_to :users
  named_scope :active, :conditions => {:is_active => true }
  named_scope :inactive, :conditions => {:is_active => false }

  def validate
    errors.add_to_base(:no_category_selected) unless self.category.present?
  end

  def self.find_user_docs(user)
    folders = []
    folder_assignment_type = user.student? ? FolderAssignmentType.find_by_name('Student') : user.employee? ? FolderAssignmentType.find_by_name('Employee') : nil
    if folder_assignment_type.present?
      folders = AssignableFolder.find_all_by_id(folder_assignment_type.assignable_folder_ids,:conditions=>{:is_active=>true},:order=>'name')      
    end
    folders
  end

  def self.fetch_users(query)
    users = []
    students = []
    archivedstudents = []
    employees = []
    archivedemployees = []
    if query.length>= 3
      students = Student.find(:all,:conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ","#{query}%","#{query}%","#{query}%","#{query}", "#{:query}" ],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
      archivedstudents = ArchivedStudent.find(:all,:conditions => ["first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR admission_no = ? OR (concat(first_name, \" \", last_name) LIKE ? ) ","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
      employees = Employee.find(:all,:conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
      archivedemployees = ArchivedEmployee.find(:all,:conditions => ["(first_name LIKE ? OR middle_name LIKE ? OR last_name LIKE ? OR employee_number = ? OR (concat(first_name, \" \", last_name) LIKE ? ))","#{params[:query]}%","#{params[:query]}%","#{params[:query]}%","#{params[:query]}", "#{params[:query]}" ],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
    else
      students = Student.find(:all,:conditions => ["admission_no = ? " ,"#{params[:query]}"],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
      archivedstudents = ArchivedStudent.find(:all,:conditions => ["admission_no = ? " ,"#{params[:query]}"],:order => "batch_id asc,first_name asc",:include =>  [{:batch=>:course}])
      employees = Employee.find(:all,:conditions => ["employee_number = ? ", "#{params[:query]}"],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
      archivedemployees = ArchivedEmployee.find(:all,:conditions => ["employee_number = ? ", "#{params[:query]}"],:order => "employee_department_id asc,first_name asc",:include=>"employee_department")
    end
    users = (students+archivedstudents+employees+archivedemployees)
    return users
  end
  
end
