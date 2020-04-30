class Assignment < ActiveRecord::Base
  belongs_to :employee
  belongs_to :subject
  has_many :assignment_answers , :dependent=>:destroy

  validates_presence_of :title, :content,:student_list, :duedate

  has_attached_file :attachment ,
    :path => "uploads/:class/:id_partition/:basename.:extension",
    :url=> "/assignments/download_attachment/:id",
    :max_file_size => 5242880,
    :reject_if => proc { |attributes| attributes.present? },
    :permitted_file_types =>[]

  validates_attachment_size :attachment, :less_than => 5242880,\
    :message=>'must be less than 5 MB.',:if=> Proc.new { |p| p.attachment_file_name_changed? }

  named_scope :active,:conditions => {:subjects=>{:is_deleted => false}},:joins=>[:subject]
  named_scope :for_student, lambda { |s|{ :conditions => ["FIND_IN_SET(?,student_list)",s],:order=>"duedate asc"} }
  named_scope :for_subject_employee, lambda {|subject_id, employee_id|
                                     {:conditions => {:subject_id => subject_id, :employees_subjects => {:employee_id => employee_id}},
                                      :joins => {:subject => :employees_subjects}, :order => "duedate desc"}}

  after_save {[:@student_ids, :@students].each{|attr| instance_variable_set(attr, nil)}}

  def accessible_for_user (user)
    return true if user.admin?
    if user.employee?
      return accessible_for_employee(user.employee_entry)
    elsif user.student?
      return student_ids.include? user.student_entry.id
    elsif user.parent?
      return student_ids.include? user.guardian_entry.current_ward.id
    end
  end

  def accessible_for_employee (employee)
    return Assignment.for_subject_employee(subject_id, employee.id).exists?(:id => id)
  end

  def employees_with_access
    Employee.all(:joins => :employees_subjects, :conditions => {:employees_subjects => {:subject_id => subject_id}})
  end

  def students
    @students ||= Student.find_all_by_id(student_ids)
  end

  def student_ids
    @student_ids ||= self.student_list.split(",").collect(&:to_i)
  end

  def assignment_student_ids
    student_list.split(",").collect{|s| s.to_i}
  end

  def student_is_part_of_assignment
    current_user=Authorization.current_user
    student = current_user.student_entry
    if assignment_student_ids.include? student.id
      return true
    else
      return false
    end
  end

  def validate
    if self.duedate.to_date < FedenaTimeSet.current_time_to_local_time(Time.now).to_date
      errors.add_to_base :date_cant_be_past_date
      return false
    else
      return true
    end
  end
  
  def valid_students
    student_ids = self.student_list.split(",")
    applicable_sids = []
    student_ids.each do |id|
      s = Student.find_by_id(id)
      if s.nil?
        s = ArchivedStudent.find_by_former_id(id)
      end
      applicable_sids << id  if s.present? && s.batch_id == self.subject.batch_id       
    end
    applicable_sids
  end  
end
