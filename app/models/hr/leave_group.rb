class LeaveGroup < ActiveRecord::Base
  
  attr_accessor :make_changes
  has_many :leave_group_leave_types, :dependent => :destroy
  has_many :employee_leave_types, :through => :leave_group_leave_types
#  has_many :leave_group_employees
#  has_many :employees, :through => :leave_group_employees
  
  
  has_many :employees ,:through => :leave_group_employees, :source => :employee, :source_type => 'Employee'
  has_many :archived_employees ,:through => :leave_group_employees, :source => :employee, :source_type => 'ArchivedEmployee'
  has_many :leave_group_employees, :dependent => :destroy
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  validates_length_of :description, :maximum => 250
  
  before_save :check_leave_type_and_employees
 # after_save :check_processing
  
  accepts_nested_attributes_for :leave_group_leave_types, :allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }
  accepts_nested_attributes_for :leave_group_employees, :allow_destroy => true, :reject_if => lambda { |l| l[:selected] == "0" }
  
  UPDATING_STATUS = {1 => :updating, 2 => :completed, 3 => :failed}.freeze
  
  def build_leave_types
    leave_types = EmployeeLeaveType.active
    group_leave_type_ids = leave_group_leave_types.collect(&:employee_leave_type_id)
    #    group_leave_types = leave_group_leave_types
    leave_types.each do |lt|
      unless group_leave_type_ids.include? lt.id
        leave_group_leave_types.build(:employee_leave_type_id => lt.id, :leave_count => lt.max_leave_count, :selected => false, :type_name => lt.name_with_code)
      else
        group_leave_type = leave_group_leave_types.detect{|l| l.employee_leave_type_id == lt.id}
        #        leave_type = leave_types.detect{|l| l.id == lt.id}
        group_leave_type.attributes = {:selected => true, :type_name => lt.name_with_code}
      end
    end
  end
  
  def build_employees(search, employees = [])
    hsh = {:thead => {:check => true, :name => t('name'), :department => t('department'), :position => t('position'), :grade => t('grade')}, :tbody => {}, :header =>[:check, :name, :department, :position, :grade], :search => search}
    employee_ids = leave_group_employees.collect(&:employee_id)
    employees.each do |emp|
      hsh[:tbody][emp.id] = {:check => (employee_ids.include? emp.id), :name => "#{emp.full_name} &#x200E;(#{emp.employee_number})&#x200E;", :department => emp.employee_department.name, :position => emp.employee_position.name, :grade => emp.employee_grade.try(:name)}
      hsh[:thead][:check] = false unless employee_ids.include? emp.id
    end
    hsh
  end
  
  def build_selected_employees(search, employees = [])
    hsh = {:thead => {:name => t('name'), :department => t('department'), :position => t('position'), :grade => t('grade')}, :tbody => {}, :header =>[:name, :department, :position, :grade, :action], :search => search, :total => employees.length, :employees_total => leave_group_employees.length}
    employees.each do |emp|
      hsh[:tbody][emp.id] = {:name => "#{emp.full_name} &#x200E;(#{emp.employee_number})&#x200E;", :department => emp.employee_department.name, :position => emp.employee_position.name, :grade => emp.employee_grade.try(:name), :action => t('remove')}
    end
    hsh
  end
  
  def check_leave_type_and_employees
    leave_group_leave_types.each do |l|
      l.mark_for_destruction if (!l.new_record? and l.selected == "0")
    end
    leave_group_employees.each do |e|
      e.mark_for_destruction if (!e.new_record? and e.selected == "0")
    end
  end
  
  def save_employees(data)
    employee_ids = leave_group_employees.collect(&:employee_id)
    count = 0
    value = {}
    saved_emp = []
    ActiveRecord::Base.transaction do
      data.each do |emp_id, values|
        unless employee_ids.include? emp_id.to_i
          lg_emp = LeaveGroupEmployee.new(:leave_group_id => id, :employee_id => emp_id.to_i, :employee_type => 'Employee')
          count += 1 if lg_emp.save
          saved_emp << emp_id if lg_emp.save
        end
      end
    end
    value[:count] = count
    value[:saved_emp] = saved_emp
    return value = {:count => count, :saved_emp => saved_emp}
  
  end
  
  def employees_count
    leave_group_employees.select{|e| e.employee_type == 'Employee'}.length
  end
  
  def leave_types_count
    leave_group_leave_types.select{|t| t.employee_leave_type.present? and t.employee_leave_type.is_active}.length
  end
  
  def self.get_hash_priority
    hash = {:employee_leave_types=>[:name,:code,:leave_count]}
    return hash
  end
  
  def check_processing
    updated_types = leave_group_leave_types.select{|l| l.update_group}
    if updated_types.present? and leave_group_employees.present?
      self.update_attributes(:updating_status => 1)
      Delayed::Job.enqueue(DelayedUpdateEmployeeLeave.new(id, updated_types.collect(&:id)))
    end
  end
  
  class << self
    def fetch_search_filters(search, select_all)
      filters = []
      search.each do |k,v|
        filter = {}
        if k == "gender_equals"
          filter[t('gender')] = [(v == "" ? t('all') : (v == "m" ? t('male') : t('female')))]
        else
          name = k.to_s.gsub('_id_in', '')
          unless (select_all||{}).keys.include? k
            klass = name.classify.constantize
            filter[t(name)] = klass.find(v).collect(&:name)
          else
            filter[t(name)] = [t('all_selected')]
          end
        end
        filters << filter
      end
      filters.each_slice(2).to_a
    end
    
    def get_employee_ids(leave_group_ids)
      employee_ids = []
      leave_groups = find(leave_group_ids, :include => :employees)
      leave_groups.to_a.each { |leave_group| employee_ids << leave_group.employees.collect(&:id) }
      employee_ids.flatten
    end
    
    def credit_leave_typs_id(params)
       leave_type_ids = []
      params.each do |key, value|
        value.to_a.each do |k, val|
          if k == 'selected' and val == '1'
            leave_type_ids << value[:employee_leave_type_id]
          end
        end
      end  
      return leave_type_ids = leave_type_ids.uniq
    end
    
  end
end
