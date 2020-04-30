#Fedena
#Copyright 2011 Foradian Technologies Private Limited
#
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

class Employee < ActiveRecord::Base
  attr_accessor :leave_group_id
  attr_accessor_with_default(:biometric_id) {BiometricInformation.find_by_user_id(user_id).try(:biometric_id)}
  VALID_BLOOD_GROUPS = ["A+", "A-","A1+","A1-","A1B+","A1B-","A2-","A2+","A2B+","A2B-" ,"B+", "B-","B1+", "O+", "O-", "AB+", "AB-"]

  belongs_to  :employee_category
  belongs_to  :employee_position
  belongs_to  :employee_grade
  belongs_to  :employee_department
  belongs_to  :nationality, :class_name => 'Country'
  belongs_to  :home_country, :class_name => 'Country'
  belongs_to  :office_country, :class_name => 'Country'
  belongs_to  :user
  belongs_to  :reporting_manager,:class_name => "User"
  has_one :payroll_group, :through => :employee_salary_structure
  has_many    :employees_subjects
  has_many    :subjects ,:through => :employees_subjects
  #  has_many    :timetable_entries
  has_and_belongs_to_many :timetable_entries, :join_table => "teacher_timetable_entries"
  has_and_belongs_to_many :subject_leaves, :join_table => "subject_leaves_teachers"
  has_many    :employee_bank_details
  has_many    :employee_additional_details,:dependent=>:destroy
  has_many    :apply_leaves
  has_many    :monthly_payslips
  has_one    :employee_salary_structure, :dependent=>:destroy
  has_many :employee_payslips, :as => :employee
  has_many    :finance_transaction_ledgers, :as => :payee
  has_many    :finance_transactions, :as => :payee
  has_many    :cancelled_finance_transactions, :foreign_key => :payee_id,:conditions=>  ['payee_type = ?', 'Employee']
  has_many    :employee_attendances
  has_many    :timetable_swaps
  has_many    :leave_reset_logs
  has_and_belongs_to_many :batches,:join_table => "batch_tutors"
  #  has_many    :individual_payslip_categories
  has_many    :employee_leaves
  has_many    :employee_leave_balances
  has_many :employee_additional_leaves
  has_one :leave_group_employee, :as => :employee
  has_one :leave_group, :through => :leave_group_employee
  
  has_many :generated_certificates, :as => :issued_for, :dependent => :destroy
  has_many :generated_id_cards, :as => :issued_for, :dependent => :destroy
  
  has_many :user_groups_users, :as  => :member
  
  named_scope :employee_number_equals, lambda{|empl_no| {:conditions => ["employee_number LIKE BINARY(?)",empl_no]}}
  named_scope :nationality_name_equals, lambda{|nname|{:joins=>[:home_country,:office_country,:nationality],:conditions=>["nationalities_employees.name like ?",nname]}}
  named_scope :home_country_name_equals, lambda{|hcname|{:joins=>[:home_country,:office_country,:nationality],:conditions=>["countries.name like ?",hcname]}}
  named_scope :office_country_name_equals, lambda{|ocname|{:joins=>[:home_country,:office_country,:nationality],:conditions=>["office_countries_employees.name like ?",ocname]}}
  named_scope :name_or_employee_number_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR employee_number LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :employee_name_as, lambda{|query|{:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?","#{query}%","#{query}%", "#{query}%", "#{query}%", "#{query}%"]}}
  named_scope :payroll_group_id_in, lambda{|query| {:joins => :employee_salary_structure, :conditions => ["employee_salary_structures.payroll_group_id IN (?)", query]}}
  named_scope :leave_group_assigned, lambda{|l_id| {:joins => :leave_group_employee, :conditions => ["leave_group_employees.leave_group_id = ?", l_id]}}
  named_scope :assigned_in_leave_group, lambda{|l_id| {:joins => "LEFT OUTER JOIN leave_group_employees ON leave_group_employees.employee_id = employees.id", :conditions => ["leave_group_employees.id IS NULL OR leave_group_employees.leave_group_id = ?", l_id]}}
  named_scope :leave_group_not_assigned, :joins => "LEFT OUTER JOIN leave_group_employees ON leave_group_employees.employee_id = employees.id", :conditions => "leave_group_employees.id IS NULL"
  named_scope :by_full_name, :order => 'first_name,last_name'
  named_scope :by_employee_number, :order => 'employee_number'
  
  #  accepts_nested_attributes_for :individual_payslip_categories,:allow_destroy=>true

  accepts_nested_attributes_for :monthly_payslips,:allow_destroy=>true
  validates_format_of     :employee_number, :with => /^[\/A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters

  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,10}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address

  validates_presence_of :employee_category_id, :employee_number, :first_name, :employee_position_id,
    :employee_department_id,  :date_of_birth,:joining_date,:nationality_id
  validates_uniqueness_of  :employee_number,:case_sensitive => false
  validates_inclusion_of :marital_status, :in => ["single", "married","divorced","widowed"],:allow_blank=>true,:message=>"should be either married,single,widowed,divorced"
  validates_inclusion_of :blood_group, :in =>VALID_BLOOD_GROUPS+["Unknown"] ,:allow_blank=>true,:message=>"should be either A+, A-,A1+,A1-,A1B+,A1B-,A2-,A2+,A2B+,A2B-, B+, B-,B1+, O+, O-, AB+ or AB-"
  #  validates_associated :user
  after_validation :create_user_and_validate
  before_save :save_biometric_info
  before_save :status_true
  after_create :save_leave_group
  after_update :update_leave_group
  before_validation :fix_blood_group # ,:if=>Proc.new{|s| s.blood_group_changed?}
  after_save :update_timetable_summary_status
  after_destroy :update_timetable_summary_status
  before_destroy :update_cancelled_finance_transactions_details
  before_create :set_last_reset_date
  before_create :set_last_credit_date
  
  before_validation :update_country_and_nationality

  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']

  has_attached_file :photo,
    :styles => {:original=> "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES

  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }

  after_create :verify_and_send_sms 

  named_scope :with_payslips, lambda{|start_date,end_date,pg_id| {
      :joins => [:employee_department, {:employee_payslips => :payslips_date_range}],
      :select => "distinct employee_payslips.net_pay,employee_payslips.reason,employee_payslips.is_rejected,employee_payslips.is_approved,employee_payslips.id AS 'payslip_id', employees.id, employees.first_name, employees.last_name, employees.employee_number, employee_departments.name, payslips_date_ranges.revision_number = employee_payslips.revision_number AS current_group",
      :conditions => ["payslips_date_ranges.start_date= ? AND payslips_date_ranges.end_date = ? AND payslips_date_ranges.payroll_group_id = ? ", start_date,end_date,pg_id],  :order => "employees.first_name"
    }}

  named_scope :without_payslips, lambda{|start_date,end_date,pg_id|
    {  :joins=>"left outer join (select ep.*, pd.start_date s_date, pd.end_date e_date from employee_payslips ep inner join payslips_date_ranges pd on pd.id=ep.payslips_date_range_id and pd.start_date = '#{start_date.to_date}' AND pd.end_date = '#{end_date.to_date}' AND pd.payroll_group_id = #{pg_id}) ep on ep.employee_id=employees.id left outer join employee_salary_structures on employee_salary_structures.employee_id = employees.id left outer join payroll_groups on payroll_groups.id = employee_salary_structures.payroll_group_id inner join employee_departments on employee_departments.id = employees.employee_department_id", :from=>'employees',
      :select => "distinct employees.id,employees.first_name,employees.last_name,employees.employee_number,employee_salary_structures.net_pay,employee_salary_structures.revision_number = payroll_groups.current_revision AS current_group,employee_departments.name, employees.last_reset_date",
      :conditions => ["ep.id IS NULL AND employee_salary_structures.payroll_group_id = ? AND employees.joining_date <= '#{end_date.to_date}'",pg_id]
    }
  }
  named_scope :approved_payslips, :conditions => ["employee_payslips.is_approved =? ",true]
  named_scope :pending_payslips,:conditions => ["employee_payslips.is_approved =? AND employee_payslips.is_rejected = ?",false,false]
  named_scope :rejected_payslips,:conditions => ["employee_payslips.is_rejected =? ",true]
  named_scope :outdated_payroll, :conditions => "employee_salary_structures.revision_number <> payroll_groups.current_revision"
  named_scope :updated_payroll, :conditions =>  "employee_salary_structures.revision_number = payroll_groups.current_revision"
  named_scope :with_lop, :joins => "INNER JOIN employee_additional_leaves AS eal ON eal.employee_id = employees.id INNER JOIN employee_leave_types ON employee_leave_types.id = eal.employee_leave_type_id ", :conditions => "eal.is_deductable = 1 AND eal.is_deducted = 0 AND employee_leave_types.lop_enabled = 1 AND employees.last_reset_date <= eal.attendance_date", :include => {:employee_additional_leaves => :employee_leave_type}
  named_scope :without_lop, :joins => "LEFT OUTER JOIN employee_additional_leaves AS eal ON eal.employee_id = employees.id AND eal.is_deductable = 1 AND eal.is_deducted = 0", :conditions => "eal.id IS NULL", :include => :employee_additional_leaves
  named_scope :payslips_for_employees, {:select => 'employees.*, ed.name AS dept_name, pr.start_date,pr.end_date, ranges.start_date as r_date, COUNT(CASE ep.is_rejected WHEN 0 THEN 1 ELSE NULL END) AS payslips_count, pg.payment_period', :joins=>"INNER JOIN employee_departments ed ON ed.id = employees.employee_department_id  LEFT OUTER JOIN employee_payslips ep ON ep.employee_id = employees.id and ep.employee_type = 'Employee' LEFT OUTER JOIN (SELECT epx.employee_id, MAX(prx.start_date) start_date FROM employee_payslips epx LEFT OUTER JOIN payslips_date_ranges prx ON prx.id=epx.payslips_date_range_id GROUP BY epx.employee_id, epx.employee_type) ranges ON ranges.employee_id = ep.employee_id LEFT OUTER JOIN payslips_date_ranges pr ON pr.id = ep.payslips_date_range_id AND ranges.start_date = pr.start_date LEFT OUTER JOIN payroll_groups pg ON pg.id= pr.payroll_group_id", :conditions => "(ep.id IS NULL AND pr.id IS NULL) OR (ep.id IS NOT NULL AND pr.id IS NOT NULL)", :include => [:payroll_group], :order=>'ed.name, employees.first_name', :group=> 'employees.employee_department_id, employees.id'}
  named_scope :load_payslips, :include => {:employee_payslips => :employee_payslip_categories}
  include CsvExportMod


  def update_timetable_summary_status
    if(self.destroyed? or self.changed.include? "employee_grade_id")
      Timetable.mark_summary_status({:model => self})
    end
  end

  def update_cancelled_finance_transactions_details
    CancelledFinanceTransaction.find_in_batches(:batch_size => 500,:conditions => {:payee_id => self.id,:payee_type => 'Employee'}) do |cfts|
      isql = "UPDATE `cancelled_finance_transactions` SET `other_details`= CASE"
      cft_ids = []
      if cfts.present?
        cfts.each do |cft|
          cft_ids << cft.id
          other_details = (cft.other_details.present? ? cft.other_details : {}).merge({:payee_name => "#{self.full_name} #{self.employee_number}"})
          isql += " WHEN `id` = #{cft.id} THEN '#{other_details.to_yaml}' "
        end
        isql += "END WHERE `id` in (#{cft_ids.join(',')});"
        RecordUpdate.connection.execute(isql)
      end
    end
  end

  def self.find_student_with_biometric(biometric_id)
    Employee.all(
      :joins=>[:user=>[:biometric_information]],
      :conditions=>{:biometric_informations=>{:biometric_id=>biometric_id}}
    )
  end


  
  def set_last_reset_date
    self.last_reset_date = self.joining_date
  end
  
  def set_last_credit_date
    self.last_credit_date = self.joining_date
  end

  def recent_payslip
    payslip = self.employee_payslips.all( :joins => :payslips_date_range, :select => "employee_payslips.*, payslips_date_ranges.start_date, payslips_date_ranges.end_date", :order => 'payslips_date_ranges.start_date').last
    if payslip.present?
      payslip_date_range = payslip.payslips_date_range
      pg = payslip_date_range.payroll_group
      pg.present? ? (payment_period = pg.payment_period) : (return "-")
      if payment_period == 5
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date,:format => :month_year) : "-")
      elsif payment_period == 1
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) : "-")
      else
        return (payslip_date_range.present? ? format_date(payslip_date_range.start_date) + " - " + format_date(payslip_date_range.end_date) : "-")
      end
    end
  end


  def verify_and_send_sms
    AutomatedMessageInitiator.employee_admission(self)
  end

  def employee_hours
    return ((employee_grade.present? and employee_grade.max_hours_week.present?) ? employee_grade.max_hours_week : 0)
  end

  def subject_hours
    return (subjects.present? ? subjects.map{|x| x.max_weekly_classes}.sum : 0)
  end
  
  def active_subjects
    return subjects.all(:include=>"batch", :joins=>:batch, :conditions=>["batches.is_active=1 and batches.is_deleted=0"])
  end
  
  def active_subject_hours
    return (active_subjects.present? ? active_subjects.map{|x| x.max_weekly_classes}.sum : 0)
  end
  #  def after_initialize
  #    self.biometric_id = biometric_id.present? ? biometric_id : BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
  #  end

  def setup_employee_leave(params_leave_type=nil)
    leave_type = self.leave_group.leave_group_leave_types.all(:joins => :employee_leave_type) if leave_group.present?
    leave_type.each do |e|
      leave_type = EmployeeLeaveType.find(e.employee_leave_type_id)
      leave_count = EmployeeLeaveType.leave_count(leave_type, self.joining_date.to_datetime, self.leave_group)
      lc = (params_leave_type.present? and params_leave_type[e.employee_leave_type_id.to_s].present?) ? params_leave_type[e.employee_leave_type_id.to_s] : leave_count
      
      EmployeeLeave.create(:reseted_at => Time.now, :employee_id => id, 
        :employee_leave_type_id => e.employee_leave_type_id, 
        :leave_count => lc, 
        :reset_date  => self.joining_date.to_datetime, :leave_group_id => e.leave_group_id)
      EmployeeLeaveBalance.create(:employee_id => id, :employee_leave_type_id => e.employee_leave_type_id, :leave_balance => 0, :leaves_added => lc,:reset_date  => self.joining_date.to_datetime,:is_inactivated => false, :leaves_taken => 0.0, :additional_leaves => 0.0)
    end
  end

  def status_true
    unless self.status==1
      self.status=1
    end
  end


  def save_biometric_info
    biometric_info = BiometricInformation.find_or_initialize_by_user_id(user_id)
    biometric_info.update_attributes(:user_id => user_id,:biometric_id => biometric_id)
    biometric_info.errors.each{|attr,msg| errors.add(attr.to_sym,"#{msg}")}
    unless errors.blank?
      #      ISSUE FIX 9089
      user_record = User.find_by_id(user_id)
      user_record.destroy if user_record.present?
      raise ActiveRecord::Rollback
    end
  end

  def validate
    errors.add(:joining_date, :not_less_than_hundred_year)  if self.joining_date.year < Date.today.year - 100 \
      if self.joining_date.present?
    errors.add(:date_of_birth, :not_less_than_hundred_year) if self.date_of_birth.year < Date.today.year - 100 \
      if self.date_of_birth.present?
    errors.add(:joining_date, :not_less_than_date_of_birth) if self.joining_date < self.date_of_birth \
      if self.date_of_birth.present? and self.joining_date.present?
    errors.add(:date_of_birth, :cant_be_a_future_date) if self.date_of_birth >= Date.today \
      if self.date_of_birth.present?
    errors.add(:gender, :error2) unless ['m', 'f'].include? self.gender.downcase \
      if self.gender.present?
    unless employee_additional_details.blank?
      employee_additional_details.each do |employee_additional_detail|
        unless employee_additional_detail.additional_info==''
          errors.add_to_base(employee_additional_detail.errors.full_messages.map{|e| e+". Please add additional details."}.join(', ')) unless employee_additional_detail.valid?
        end
      end
    end
  end

  def create_user_and_validate
    if self.new_record?
      user_record = self.build_user
      user_record.first_name = self.first_name
      user_record.last_name = self.last_name
      user_record.username = self.employee_number.to_s
      user_record.password = self.employee_number.to_s + "123"
      user_record.role = 'Employee'
      user_record.email = self.email.blank? ? "" : self.email.to_s
      check_user_errors(user_record)
    else
      changes_to_be_checked = ['employee_number','first_name','last_name','email']
      check_changes = self.changed & changes_to_be_checked
      #      self.user.role ||= "Employee"
      unless check_changes.blank?
        emp_user = self.user
        emp_user.username = self.employee_number if check_changes.include?('employee_number')
        emp_user.password = self.employee_number.to_s + "123" if check_changes.include?('employee_number')
        emp_user.first_name = self.first_name if check_changes.include?('first_name')
        emp_user.last_name = self.last_name if check_changes.include?('last_name')
        emp_user.email = self.email.to_s if check_changes.include?('email')
        emp_user.save if check_user_errors(self.user)
      end
    end
  end
  
  def gender_tag
    gender.downcase == "f" ? "#{t('female')}" : "#{t('male')}"
  end

  def total_experience_tag
    years = self.find_experience_years
    months = self.find_experience_months
    year = months/12
    month = months%12
    total_years = years + year
    total_months = month
    return "#{total_years.to_s} #{t('years')} #{total_months.to_s} #{t('months')}"
  end

  def check_user_errors(user)
    unless user.valid?
      er_attrs = []
      errors.each do|a,m|
        er_attrs.push([t(a.to_sym),"#{m}"])
      end
      user.errors.each{|attr,msg| errors.add(t(attr.to_sym),"#{msg}") unless er_attrs.include?([t(attr.to_sym),"#{msg}"]) }
    end
    user.errors.blank?
  end

  def employee_batches
    batches_with_employees = Batch.active.reject{|b| b.employee_id.nil?}
    assigned_batches = batches_with_employees.reject{|e| !e.employee_id.split(",").include?(self.id.to_s)}
    return assigned_batches
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename     = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data         = input_data.read
  end

  def max_hours_per_day
    self.employee_grade.max_hours_day unless self.employee_grade.blank?
  end

  def max_hours_per_week
    self.employee_grade.max_hours_week unless self.employee_grade.blank?
  end
  alias_method(:max_hours_day, :max_hours_per_day)
  alias_method(:max_hours_week, :max_hours_per_week)

  def next_employee
    next_st = self.employee_department.employees.first(:conditions => "id>#{self.id}",:order => "id ASC")
    next_st ||= employee_department.employees.first(:order => "id ASC")
    next_st ||= self.employee_department.employees.first(:order => "id ASC")
  end

  def previous_employee
    prev_st = self.employee_department.employees.first(:conditions => "id<#{self.id}",:order => "id DESC")
    prev_st ||= employee_department.employees.first(:order => "id DESC")
    prev_st ||= self.employee_department.empoyees.first(:order => "id DESC")
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def is_payslip_approved(date)
    approve = MonthlyPayslip.find_all_by_salary_date_and_employee_id(date,self.id,:conditions => ["is_approved = true"])
    if approve.empty?
      return false
    else
      return true
    end
  end

  #  def create_default_menu_links
  #    default_links = MenuLink.find_all_by_user_type("employee")
  #    self.user.menu_links = default_links
  #  end

  def is_payslip_rejected(date)
    approve = MonthlyPayslip.find_all_by_salary_date_and_employee_id(date,self.id,:conditions => ["is_rejected = true"])
    if approve.empty?
      return false
    else
      return true
    end
  end

  def self.total_employees_salary(employees,start_date,end_date)
    salary = 0
    employees.each do |e|
      salary_dates = e.all_salaries(start_date,end_date)
      salary_dates.each do |s|
        salary += e.employee_salary(s.salary_date.to_date)
      end
    end
    salary
  end

  def employee_salary(salary_date)

    monthly_payslips = MonthlyPayslip.find(:all,
      :order => 'salary_date desc',
      :conditions => ["employee_id ='#{self.id}'and salary_date = '#{salary_date}' and is_approved = 1"])
    individual_payslip_category = IndividualPayslipCategory.find(:all,
      :order => 'salary_date desc',
      :conditions => ["employee_id ='#{self.id}'and salary_date >= '#{salary_date}'"])
    individual_category_non_deductionable = 0
    individual_category_deductionable = 0
    individual_payslip_category.each do |pc|
      unless pc.is_deduction == true
        individual_category_non_deductionable = individual_category_non_deductionable + pc.amount.to_f
      end
    end

    individual_payslip_category.each do |pc|
      unless pc.is_deduction == false
        individual_category_deductionable = individual_category_deductionable + pc.amount.to_f
      end
    end

    non_deductionable_amount = 0
    deductionable_amount = 0
    monthly_payslips.each do |mp|
      category1 = PayrollCategory.find(mp.payroll_category_id)
      unless category1.is_deduction == true
        non_deductionable_amount = non_deductionable_amount + mp.amount.to_f
      end
    end

    monthly_payslips.each do |mp|
      category2 = PayrollCategory.find(mp.payroll_category_id)
      unless category2.is_deduction == false
        deductionable_amount = deductionable_amount + mp.amount.to_f
      end
    end
    net_non_deductionable_amount = individual_category_non_deductionable + non_deductionable_amount
    net_deductionable_amount = individual_category_deductionable + deductionable_amount

    net_amount = net_non_deductionable_amount - net_deductionable_amount
    return net_amount.to_f
  end


  def salary(start_date,end_date)
    MonthlyPayslip.find_by_employee_id(self.id,:order => 'salary_date desc',
      :conditions => ["salary_date >= '#{start_date.to_date}' and salary_date <= '#{end_date.to_date}' and is_approved = 1"]).salary_date

  end


  def all_salaries(start_date,end_date)
    MonthlyPayslip.find_all_by_employee_id(self.id,:select =>"distinct salary_date" ,:order => 'salary_date desc',
      :conditions => ["salary_date >= '#{start_date.to_date}' and salary_date <= '#{end_date.to_date}' and is_approved = 1"])
  end

  def self.calculate_salary(monthly_payslip,individual_payslip_category)
    individual_category_non_deductionable = 0
    individual_category_deductionable = 0
    unless individual_payslip_category.blank?
      individual_payslip_category.each do |pc|
        if pc.is_deduction == true
          individual_category_deductionable = individual_category_deductionable + pc.amount.to_f
        else
          individual_category_non_deductionable = individual_category_non_deductionable + pc.amount.to_f
        end
      end
    end
    non_deductionable_amount = 0
    deductionable_amount = 0
    unless monthly_payslip.blank?
      monthly_payslip.first.employee_payslip_categories.each do |mp|
        if mp.payroll_category.present?
          if mp.payroll_category.is_deduction == true
            deductionable_amount = deductionable_amount + mp.amount.to_f
          else
            non_deductionable_amount = non_deductionable_amount + mp.amount.to_f
          end
        end
      end
    end
    if monthly_payslip.first.lop.present?
      deductionable_amount+= monthly_payslip.first.lop.to_f
    end
    net_non_deductionable_amount = individual_category_non_deductionable + non_deductionable_amount
    net_deductionable_amount = individual_category_deductionable + deductionable_amount
    net_amount = net_non_deductionable_amount - net_deductionable_amount

    return_hash = {:net_amount=>monthly_payslip.first.net_pay,:net_deductionable_amount=>net_deductionable_amount,\
        :net_non_deductionable_amount=>net_non_deductionable_amount }
    return_hash
  end

  def self.find_in_active_or_archived(id)
    employee = Employee.find(:first,:conditions=>"id=#{id}")
    if employee.blank?
      return  ArchivedEmployee.find(:first,:conditions=>"former_id=#{id}")
    else
      return employee
    end
  end

  def has_dependency
    return true if self.employee_payslips.present? or self.employees_subjects.present? \
      or self.apply_leaves.present? or self.finance_transactions.present? \
      or self.timetable_entries.present? or self.employee_attendances.present? \
      or self.timetable_swaps.present? or self.user.recieved_finance_transactions.present?
    return true if FedenaPlugin.check_dependency(self,"permanant").present?
    return false
  end

  def former_dependency
    FedenaPlugin.check_dependency(self,"former")
  end

  def find_experience_years
    exp_years = self.experience_year
    date = Date.today
    total_current_exp_days = (date-self.joining_date).to_i
    current_years = (total_current_exp_days/365)
    unless (self.joining_date > date)
      return exp_years.nil? ? current_years : exp_years+current_years
    else
      return exp_years.nil? ? 0 : exp_years
    end
  end

  def find_experience_months
    exp_months = self.experience_month
    date = Date.today
    total_current_exp_days = (date-self.joining_date).to_i
    rem = total_current_exp_days%365
    current_months = rem / 30
    unless (self.joining_date > date)
      return exp_months.nil? ? current_months : exp_months+current_months
    else
      return exp_months.nil? ? 0 : exp_months
    end
  end

  def get_profile_data
    employee = self
    biometric_id = BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
    salary_details = employee_salary_structure
    additional_data = Hash.new
    bank_data = Hash.new
    additional_fields = AdditionalField.all(:conditions=>"status = true")
    additional_fields.each do |additional_field|
      detail = EmployeeAdditionalDetail.find_by_additional_field_id_and_employee_id(additional_field.id,employee.id)
      additional_data[additional_field.name] = detail.try(:additional_info)
    end
    bank_fields = BankField.all(:conditions=>"status = true")
    bank_fields.each do |bank_field|
      detail = EmployeeBankDetail.find_by_bank_field_id_and_employee_id(bank_field.id,employee.id)
      bank_data[bank_field.name] = detail.try(:bank_info)
    end
    exp_years = employee.experience_year
    exp_months = employee.experience_month
    date = Date.today
    total_current_exp_days = (date-employee.joining_date).to_i
    current_years = (total_current_exp_days/365)
    rem = total_current_exp_days%365
    current_months = rem/30
    total_month = (exp_months || 0)+current_months
    year = total_month/12
    month = total_month%12
    total_years = (exp_years || 0)+current_years+year
    total_months = month
    [employee,additional_data,bank_data,total_years,total_months,salary_details,biometric_id]
  end
  
  def self.get_hash_priority
    hash = {:employee_additional_details=>[:name,:value],:employee_bank_details=>[:name,:value]}
    return hash
  end

  def self.employee_details(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      employees=Employee.all(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:order=>'first_name ASC')
    else
      employees=Employee.all(:select=>"employees.first_name,employees.middle_name,employees.last_name,employee_number,joining_date,employee_departments.name as department_name,employee_positions.name as emp_position,gender , employees.id as emp_id,users.first_name as manager_first_name ,users.last_name as manager_last_name" ,:joins=>"INNER JOIN `employee_departments` ON `employee_departments`.id = `employees`.employee_department_id INNER JOIN `employee_positions` ON `employee_positions`.id = `employees`.employee_position_id LEFT OUTER JOIN `users` ON `users`.id = `employees`.reporting_manager_id",:order=>sort_order)
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('joining_date') }","#{t('department')}","#{t('position')}","#{t('manager')}","#{t('gender')}"]
    data << col_heads
    employees.each_with_index do |e,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{e.full_name}"
      col<< "#{e.employee_number}"
      col<< "#{format_date(e.joining_date)}"
      col<< "#{e.department_name}"
      col<< "#{e.emp_position}"
      col<< "#{e.manager_first_name} #{e.manager_last_name}"
      col<< "#{e.gender.downcase=='m' ? t('m') : t('f')}"
      col=col.flatten
      data<< col
    end
    return data
  end

  def self.employee_subject_association(parameters)
    sort_order=parameters[:sort_order]
    if sort_order.nil?
      employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:order=>'first_name ASC',:include=>{:subjects=>[:employees_subjects,{:batch=>:course}]})
    else
      employees= Employee.all(:select=>"first_name,middle_name,last_name,employees.id,employee_departments.name as department_name,count(employees_subjects.id) as emp_sub_count,employee_number",:joins=>[:employees_subjects,:employee_department],:group=>"employees.id",:order=>sort_order,:include=>{:subjects=>[:employees_subjects,{:batch=>:course}]})
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('department')}","#{t('subject')}(#{t('batch_name')})"]
    data << col_heads
    employees.each_with_index do |obj,i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.employee_number}"
      col << "#{obj.department_name}"
      col << "#{obj.subjects.map{|s| "#{s.name} ( #{s.batch.course.code} #{s.batch.name} )"}.join("\n" )}"
      col=col.flatten
      data << col
    end
    return data
  end

  def self.employee_payroll_details(parameters)
    sort_order = parameters[:sort_order]
    department_id = parameters[:department_id]
    if department_id.nil? or department_id.blank?
      employees = Employee.all(:select => "first_name, middle_name, last_name,employees.id, employee_departments.name as department_name, payroll_groups.name as payroll_group_name, employee_number", :joins => "LEFT OUTER JOIN employee_salary_structures ON employee_salary_structures.employee_id = employees.id LEFT OUTER JOIN payroll_groups ON payroll_groups.id = employee_salary_structures.payroll_group_id INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id",:include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :order => (sort_order.nil? ? 'first_name ASC' : sort_order))
    else
      employees = Employee.all(:select => "first_name, middle_name, last_name,employees.id, employee_departments.name as department_name, payroll_groups.name as payroll_group_name, employee_number", :joins => "LEFT OUTER JOIN employee_salary_structures ON employee_salary_structures.employee_id = employees.id LEFT OUTER JOIN payroll_groups ON payroll_groups.id = employee_salary_structures.payroll_group_id INNER JOIN employee_departments ON employee_departments.id = employees.employee_department_id",:include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}}, :conditions => ["employee_departments.id=?", department_id], :order => (sort_order.nil? ? 'first_name ASC' : sort_order))
    end
    data=[]
    col_heads=["#{t('no_text')}","#{t('name')}","#{t('employee_id') }","#{t('department')}", "#{t('payroll_group')}","#{t('payroll_text')} #{t('details')}(#{Configuration.currency})"]
    data << col_heads
    employees.each_with_index do |e,i|
      col=[]
      col<< "#{i+1}"
      col<< "#{e.full_name}"
      col<< "#{e.employee_number}"
      col<< "#{e.department_name}"
      col<< "#{e.payroll_group_name}"
      payroll = e.employee_salary_structure
      unless payroll.nil?
        earnings = e.employee_salary_structure.earning_components
        deductions = e.employee_salary_structure.deduction_components
        total_earnings = 0
        total_deductions = 0
        pay=[]
        col << "#{t('gross_pay')} - #{payroll.gross_salary}"
        data << col
        data << ["", "", "", "", "", "#{t('earnings')}"]
        earnings.each do |ear|
          data << ["", "", "", "", "", "#{ear.payroll_category.try(:name)} - #{ear.amount.blank? ? 0.00 :ear.amount}"]
          total_earnings += ear.amount.to_f
        end
        data << ["", "", "", "", "", "#{t('total_earning')} - #{total_earnings}"]
        data << ["", "", "", "", "", "#{t('deductions')}"]
        deductions.each do |ded|
          data << ["", "", "", "", "", "#{ded.payroll_category.try(:name)} - #{ded.amount.blank? ? 0.00 :ded.amount}"]
          total_deductions += ded.amount.to_f
        end
        data << ["", "", "", "", "", "#{t('total_deduction')} - #{total_deductions}"]
        data << ["", "", "", "", "", "#{t('net_pay')} - #{payroll.net_pay}"]
      else
        col<< "-"
        data<< col
      end
      col=col.flatten

    end
    return data
  end

  def self.get_employees(department)
    unless (department == "All Departments")
      employees = Employee.all(:select=>"employees.id,employees.first_name,employees.middle_name,employees.last_name,employees.employee_number",:joins=>[:employee_leaves],:conditions => ["employee_leaves.leave_taken > employee_leaves.leave_count and employees.employee_department_id = ?",department],:include => [{:employee_leaves => :employee_leave_type }])
    else
      employees = Employee.all(:select => "employees.id,employees.first_name,employees.middle_name,employees.last_name,employees.employee_number",:joins=>[:employee_leaves],:conditions => "employee_leaves.leave_taken > employee_leaves.leave_count" ,:include => [{:employee_leaves => :employee_leave_type }])
    end
  end

  def self.fetch_employee_advance_search_data(params)
    employee_advance_search params
  end

  def build_salary_structure(pay_group, apply, gross_pay = nil, dependencies = {}, category_id = nil)
    if payroll_group.nil?
      payroll = pay_group.employee_payroll(gross_pay, id, 1, dependencies, category_id) unless gross_pay.nil?
      salary_structure = EmployeeSalaryStructure.new(:employee_id => id, :payroll_group_id => pay_group.id, :gross_salary => gross_pay, :revision_number => pay_group.current_revision)
      cat_ids = pay_group.payroll_categories.collect(&:id)
      pay_group.payroll_categories.each do |cat|
        salary_structure.employee_salary_structure_components.build(:payroll_category_id => cat.id, :amount => (payroll.present? ? payroll[cat.code].to_s : nil), :pc_name => cat.name)
      end
    elsif payroll_group.present? and payroll_group.id == pay_group.id
      salary_structure = employee_salary_structure
      if apply.to_i == 1 and !employee_salary_structure.current_group
        payroll = payroll_group.employee_payroll(gross_pay || employee_salary_structure.gross_salary, id, apply.to_i, dependencies, category_id)
        sal_cat_ids = salary_structure.employee_salary_structure_components.collect(&:payroll_category_id)
        cat_ids = payroll_group.payroll_categories.collect(&:id)
        payroll_group.payroll_categories.each do |cat|
          salary_structure.employee_salary_structure_components.build(:payroll_category_id => cat.id, :amount => payroll[cat.code].to_s, :pc_name => cat.name) unless sal_cat_ids.include? cat.id
        end
        cat_ids = payroll_group.payroll_category_ids
        salary_structure.employee_salary_structure_components.each{|c| (c.destroyed = true unless cat_ids.include? c.payroll_category_id)}
        salary_structure.gross_salary = gross_pay || employee_salary_structure.gross_salary
        salary_structure.employee_salary_structure_components.each{|c| c.amount = payroll[c.payroll_category.code].to_s }
        salary_structure.revision_number = pay_group.current_revision
      elsif gross_pay.present?
        salary_structure.gross_salary = gross_pay
        payroll = pay_group.employee_payroll(gross_pay, id, apply.to_i, dependencies, category_id)
        salary_structure.employee_salary_structure_components.each{|c| c.amount = payroll[c.payroll_category.code].to_s }
      end
      cat_ids = salary_structure.employee_salary_structure_components.collect(&:payroll_category_id)
      salary_structure.employee_salary_structure_components.each{|c| c.pc_name = c.payroll_category.try(:name)}
    elsif payroll_group.present? and payroll_group.id != pay_group.id
      payroll = pay_group.employee_payroll(gross_pay || employee_salary_structure.gross_salary, id, 1, dependencies, category_id)
      salary_structure = EmployeeSalaryStructure.new(:employee_id => id, :payroll_group_id => pay_group.id, :gross_salary => employee_salary_structure.gross_salary, :revision_number => pay_group.current_revision)
      cat_ids = pay_group.payroll_categories.collect(&:id)
      pay_group.payroll_categories.each do |cat|
        salary_structure.employee_salary_structure_components.build(:payroll_category_id => cat.id, :amount => payroll[cat.code].to_s, :pc_name => cat.name)
      end
      salary_structure.gross_salary = gross_pay if gross_pay.present?
    end
    return salary_structure
  end

  def check_pending_payslips
    employee_payslips.all(:conditions => "is_approved = 0 AND is_rejected = 0", :include => :payslips_date_range)
  end

  def check_pending_and_rejected_payslips
    employee_payslips.all(:conditions => "is_approved = 0", :include => :payslips_date_range, :joins => :payslips_date_range, :order => "payslips_date_ranges.start_date desc")
  end

  def check_rejected_payslips
    employee_payslips.all(:conditions => "is_approved = 0 AND is_rejected = 1", :include => :payslips_date_range)
  end

  def pending_payslips_present
    employee_payslips.select{|w| w.is_approved == false}.present?
  end

  def self.load_salary_structure(emp_id)
    find(emp_id, :include => {:employee_salary_structure => {:employee_salary_structure_components => :payroll_category}})
  end

  def self.payroll_assigned_employees(pg_id, pg_no, dept_id)
    if dept_id.nil? or dept_id == "All"
      paginate(:select => "employees.*, MAX(payslips_date_ranges.start_date) AS rec_payslip", :joins => "INNER JOIN employee_salary_structures ON (employees.id = employee_salary_structures.employee_id) INNER JOIN payroll_groups ON (payroll_groups.id = employee_salary_structures.payroll_group_id) LEFT OUTER JOIN employee_payslips ON employee_payslips.employee_id = employees.id AND employee_payslips.is_approved = 1 LEFT OUTER JOIN payslips_date_ranges ON employee_payslips.payslips_date_range_id = payslips_date_ranges.id AND payslips_date_ranges.payroll_group_id = payroll_groups.id", :include => [:employee_department, :employee_category, :employee_payslips, :payroll_group],:conditions => ["payroll_groups.id = ?",pg_id], :group => "employees.id",:per_page => 10, :page => pg_no, :order => "employees.first_name")
    else
      paginate(:select => "employees.*, MAX(payslips_date_ranges.start_date) AS rec_payslip", :joins => "INNER JOIN employee_salary_structures ON (employees.id = employee_salary_structures.employee_id) INNER JOIN payroll_groups ON (payroll_groups.id = employee_salary_structures.payroll_group_id) LEFT OUTER JOIN employee_payslips ON employee_payslips.employee_id = employees.id AND employee_payslips.is_approved = 1 LEFT OUTER JOIN payslips_date_ranges ON employee_payslips.payslips_date_range_id = payslips_date_ranges.id AND payslips_date_ranges.payroll_group_id = payroll_groups.id",:conditions => ["payroll_groups.id = ? AND employees.employee_department_id = ?",pg_id, dept_id], :group => "employees.id",:per_page => 10, :page => pg_no, :include => [:employee_category, :employee_payslips, :payroll_group], :order => "employees.first_name")
    end
  end

  def self.payroll_assign_employees(pg_id, pg_no, dept_id)
    paginate(:joins => "LEFT OUTER JOIN employee_salary_structures ON (employees.id = employee_salary_structures.employee_id) LEFT OUTER  JOIN payroll_groups ON (payroll_groups.id = employee_salary_structures.payroll_group_id)", :include => [:payroll_group, :employee_category, :employee_payslips], :conditions => ["employees.employee_department_id = ? AND (payroll_groups.id IS NULL or payroll_groups.id <> ?)", dept_id, pg_id], :per_page => 10, :page => pg_no, :order => "employees.first_name")
  end

  def self.find_scope (payslips,payslip_status)
    payslip_scope = "#{payslip_status}_payslips" if ["pending","rejected","approved"].include? payslip_status
    payslip_scope.present? ? payslips.send(payslip_scope) : false


  end

  def employee_not_deducted_leaves
    reset_date = self.last_reset_date
    count = 0
    additional_leaves = employee_additional_leaves.select{|e| e.is_deductable and !e.is_deducted and reset_date <= e.attendance_date and e.employee_leave_type.lop_enabled}
    additional_leaves.each{|l| count += (l.is_half_day ? 0.5 : 1)}
    return count
  end

  def employee_settings(payslip_id = nil)
    @payslip = EmployeePayslip.find(payslip_id) unless payslip_id.nil?
    @new_record = self.new_record?
    employee = Employee.find(self.id, :include => [:payroll_group, :employee_department, :employee_bank_details, :employee_additional_details])  unless @new_record

    setting = {:employee_details => [],
      :additional_details => [],
      :bank_details => [],
      :attendance_details => [],
      :payroll_details => []
    }

    payslip_setting = PayslipSetting.all
    if payslip_setting.present?
      setting.each do |k,v|
        fields = payslip_setting.select{|ps| ps.section == k.to_s}.first
        @field_ids = fields.fields
        unless k == :bank_details or k == :additional_details
          @field_ids.each do |id|
            detail = eval("PayslipSetting::#{k.to_s.camelize.titleize.split(" ").join("_").upcase}[#{id}]")
            emp_val = self.instance_eval("#{detail.to_s}")
            setting[k] << { detail => emp_val} if emp_val.present?
          end
        else
          self.instance_eval("#{k.to_s}").each do |row|
            setting[k] << {row.name => (@new_record ? "XYZ" : row.info)}
          end
        end
      end
    else
      setting[:employee_details] = [{:employee_name => employee.full_name},{:employee_number => employee.employee_number}, {:department => employee.department}, {:joining_date => employee.joining_date}]
      setting[:attendance_details] = [{:lop => self.lop},{:no_of_working_days => (@payslip.try(:working_days)||SalaryWorkingDay.get_working_days(@payslip.payslips_date_range.payroll_group.payment_period))}, {:no_of_days_present => self.no_of_days_present}, {:no_of_days_absent => self.no_of_days_absent}]
      setting[:payroll_details] = [{:payroll_type => self.payroll_type} , {:payment_frequency => self.payment_frequency}]
    end
    setting.delete_if { |key, value| value.blank? }
    return setting
  end
  
  def leave_details(payslip_id)
    payslip = EmployeePayslip.find(payslip_id)
    employee = Employee.find(self.id, :include=>[:employee_attendances])
    leave_types = {}
    EmployeeLeaveType.leave_type_detials.each{|code| leave_types[code] = 0}
    total_emp_leaves = employee.employee_attendances(:conditions => ["attendance_date between ? AND ?",
        payslip.payslips_date_range.start_date, payslip.payslips_date_range.end_date])
    emp_attendances = total_emp_leaves.group_by{|v| v.employee_leave_type.code}
    emp_attendances.each_pair do |code, entries|
      leave_types[code] = entries.count
    end
    leave_types["total_leave"] = total_emp_leaves.count
    leave_types["no_of_days_present"] = payslip.working_days.to_i - leave_types["total_leave"]
    return leave_types
  end

  def bank_details
    if @new_record
      return BankField.all(:conditions => ["id IN (?)",@field_ids], :select => "bank_fields.name")
    else
      return self.employee_bank_details.all(:joins => :bank_field, :conditions => ["bank_field_id IN (?)",@field_ids], :select => "bank_fields.name, employee_bank_details.bank_info as info ")
    end
  end


  def lop
    if @new_record
      return 2
    else
      start_date = @payslip.payslips_date_range.start_date.to_date
      end_date = @payslip.payslips_date_range.end_date.to_date
      range_lev = @payslip.payslip_additional_leaves.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
      range_lev_days = get_leave_count(range_lev)
      if (@payslip.days_count.to_f - range_lev_days) > 0
        return "#{range_lev_days} + #{("%g" % ("%.2f" % (@payslip.days_count.to_f - range_lev_days)))}*"
      else
        return @payslip.days_count
      end
    end
  end
  
  def prev_lops_present(payslip)
    start_date = payslip.payslips_date_range.start_date.to_date
    end_date = payslip.payslips_date_range.end_date.to_date
    range_lev = payslip.payslip_additional_leaves.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
    range_lev_days = get_leave_count(range_lev)
    t('prev_month_lop_info') if (payslip.days_count.to_f - range_lev_days) > 0
  end


  def no_of_working_days
    unless @new_record
      return @payslip.working_days
    else
      return 30
    end
  end

  def no_of_days_present
    if @new_record
      "28"
    else
      working_days = @payslip.working_days
      end_date = @payslip.payslips_date_range.end_date.to_date
      if [self.joining_date.to_date.month,self.joining_date.to_date.year] == [@payslip.payslips_date_range.start_date.to_date.month,@payslip.payslips_date_range.start_date.to_date.year]
        start_date = self.joining_date.to_date - 1.day
        working_days = end_date - start_date
      else
        start_date = @payslip.payslips_date_range.start_date.to_date
      end
      absent = self.employee_attendances.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
      absent_count = get_leave_count(absent)
      return ("%g" % ("%.2f" % (working_days.to_f - absent_count)))
    end
  end

  def no_of_days_absent
    if @new_record
      "2"
    else
      start_date = @payslip.payslips_date_range.start_date.to_date
      end_date = @payslip.payslips_date_range.end_date.to_date
      absent = self.employee_attendances.all(:conditions => ["attendance_date between ? AND ?", start_date,end_date])
      get_leave_count(absent)
    end
  end

  def get_leave_count(leaves)
    leaves.inject(0){|sum,e| sum += (e.is_half_day ? 0.5 : 1)}
  end
  
  def fetch_attendance_details(payslip)
    @payslip = payslip
    @new_record = self.new_record?
    details = {:no_of_working_days => no_of_working_days, :no_of_days_present => no_of_days_present, :no_of_days_absent => no_of_days_absent, :loss_of_pay_leaves => lop||0}
    present_per = (details[:no_of_days_present].to_f/details[:no_of_working_days].to_f)*100
    present_no = "#{details[:no_of_days_present]} | #{("%g" % ("%.2f" % present_per))} %"
    details[:no_of_days_present] = present_no
    return details
  end
  
  def payroll_type
    @new_record ? "Salaried" : t(PayrollGroup::SALARY_TYPE[@payslip.payslips_date_range.payroll_group.salary_type])
  end

  def payment_frequency
    @new_record ? "Monthly" : t(PayrollGroup::PAYMENT_PERIOD[@payslip.payslips_date_range.payroll_group.payment_period])
  end

  def additional_details
    if @new_record
      return AdditionalField.all(:conditions => ["id IN (?)",@field_ids], :select => "additional_fields.name")
    else
      return self.employee_additional_details.all(:joins => :additional_field, :conditions => ["additional_field_id IN (?)",@field_ids], :select => "additional_fields.name, employee_additional_details.additional_info as info")
    end
  end

  def employee_no
    @new_record ? "EMP01" : self.employee_number
  end

  def category
    @new_record ? "Sytem Admin" : (self.employee_category.name if self.employee_category)
  end

  def grade
    @new_record ? "Sytem Admin" : (self.employee_grade.name if self.employee_grade)
  end

  def position
    @new_record ? "Sytem Admin" : (self.employee_position.name if self.employee_position)
  end

  def department
    @new_record ? "Sytem Admin" : self.employee_department.name
  end

  def date_of_joining
    @new_record ? format_date("2015-02-01") : format_date(self.joining_date)
  end

  def employee_name
    @new_record ? "Name" : self.full_name
  end

  def is_a_batch_tutor?
    self.batches.present?
  end

  def is_a_tutor_for_this_batch(batch)
    assigned_batch_ids=self.batches.collect(&:id)
    assigned=assigned_batch_ids.include?(batch.id)
    return assigned
  end

  def associate_employees
    Employee.find(:all, :conditions=>["reporting_manager_id=#{self.user_id}"])
  end
  # FIXME workaround for authorization bug
  def employee_entry
    self
  end
  def self.search_by_employee_no_or_name(search_string)
    search_string.strip!
    scoped(:conditions => ["(ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                        OR employee_number = ? OR (concat(trim(first_name), \" \", trim(last_name)) LIKE ? )
                          OR (concat(trim(first_name), \" \", trim(middle_name), \" \", trim(last_name)) LIKE ? ))",
        "#{search_string}%","#{search_string}%","#{search_string}%",
        "#{search_string}", "#{search_string}%", "#{search_string}%" ])
  end

  def lop_enabled
    self.payroll_group.present? && self.payroll_group.enable_lop?
  end

  def get_lop_cache_key
    group = payroll_group
    "lop_amount/#{id}/#{self.class}/#{group.id}/#{group.updated_at.to_i}"
  end
  def blood_group
    if read_attribute(:blood_group).blank? && !blood_group_changed?
      # return I18n.t('unknown')
      return "Unknown"
    else
      super
    end
  end
  def fix_blood_group
    self.blood_group = nil if  read_attribute(:blood_group).blank?
    self.blood_group = nil  if ["Unknown","unknown",I18n.t('unknown'),"",nil].include? read_attribute(:blood_group)
  end
  
  def update_country_and_nationality
    self.nationality_id = Configuration.default_country unless nationality_id.present?
    self.home_country_id = Configuration.default_country unless home_country_id.present?
  end  
  
  def save_leave_group
    if leave_group_id.present?
      emp_lev = LeaveGroupEmployee.new(:leave_group_id => leave_group_id, :employee_id => id, :employee_type => 'Employee')
      setup_employee_leave if emp_lev.save
    end
  end
  
  def update_leave_group
    if leave_group_id.present?
      if leave_group_employee.present?
        leave_group_employee.update_attributes(:leave_group_id => leave_group_id)
      else
        emp_lev = LeaveGroupEmployee.new(:leave_group_id => leave_group_id, :employee_id => id, :employee_type => 'Employee')
        emp_lev.save
      end
    end
  end
  
  def leave_balance(start_date,end_date,type=nil)
    leave_balance_on_start_hash = Hash.new
    leave_balance_on_end_hash = Hash.new
    leave_added_hash = Hash.new
    leave_taken_hash = Hash.new
    all_leave_balance_records = self.employee_leave_balances
    employee_leaves = self.employee_leaves
    employee_leaves.each do |emp_leave|
      leave_balance_at_very_next_reset = 0.0
      leave_taken_btw_start_and_end_date = 0.0
      addl_leave_taken_btw_start_and_end_date = 0.0
      leave_balance_on_end = 0.0
      is_emp_leave_after_end_greater = false
      emp_leave_count = emp_leave.leave_count
      employee_leave_type = emp_leave.employee_leave_type
      employee_attendances_in_btw = self.employee_attendances.select{|ea| ea.attendance_date >= start_date.to_date and ea.attendance_date <= end_date.to_date and ea.employee_leave_type_id == emp_leave.employee_leave_type_id}
      employee_attendances_in_btw.each{|ea| leave_taken_btw_start_and_end_date += ea.is_half_day ? 0.5 : 1.0} if employee_attendances_in_btw.present?
      addl_employee_attendances_in_btw = self.employee_additional_leaves.select{|eal| eal.attendance_date >= start_date.to_date and eal.attendance_date <= end_date.to_date and eal.employee_leave_type_id == emp_leave.employee_leave_type_id}
      addl_employee_attendances_in_btw.each{|eal| addl_leave_taken_btw_start_and_end_date += eal.is_half_day ? 0.5 : 1.0} if addl_employee_attendances_in_btw.present?
      emp_lev_bal_for_lt = all_leave_balance_records.select{|elb| elb.employee_leave_type_id == emp_leave.employee_leave_type_id}
      if all_leave_balance_records.present? and emp_lev_bal_for_lt.compact.present?
        employee_leave_balance_after_end_date = all_leave_balance_records.select{|elb| elb.reset_date > end_date.to_date and elb.employee_leave_type_id == emp_leave.employee_leave_type_id }.sort_by(&:reset_date).first
        if employee_leave_balance_after_end_date.present?
          #Leave Balance Record found after the end date
          leave_taken_in_btw_end_and_next_reset = 0.0
          addl_leave_taken_in_btw_end_and_next_reset = 0.0
          leave_balance_at_very_next_reset = employee_leave_balance_after_end_date.leave_balance
          employee_attendances_btw_end_date_and_balance_record = self.employee_attendances.select{|ea| ea.attendance_date >= end_date.to_date and ea.attendance_date <= employee_leave_balance_after_end_date.reset_date and ea.employee_leave_type_id == emp_leave.employee_leave_type_id}
          employee_addl_attendances_btw_end_date_and_balance_record = self.employee_additional_leaves.select{|eal| eal.attendance_date >= end_date.to_date and eal.attendance_date <= employee_leave_balance_after_end_date.reset_date and eal.employee_leave_type_id == emp_leave.employee_leave_type_id}
          if employee_attendances_btw_end_date_and_balance_record.compact.present?
            employee_attendances_btw_end_date_and_balance_record.each{|ea| leave_taken_in_btw_end_and_next_reset += ea.is_half_day ? 0.5 : 1.0}
          end
          if employee_addl_attendances_btw_end_date_and_balance_record.compact.present?
            employee_addl_attendances_btw_end_date_and_balance_record.each{|ea| addl_leave_taken_in_btw_end_and_next_reset += ea.is_half_day ? 0.5 : 1.0}
          end
          if emp_leave.is_additional
            if emp_leave.is_active
              leave_balance_on_end = leave_balance_at_very_next_reset + leave_taken_in_btw_end_and_next_reset - addl_leave_taken_in_btw_end_and_next_reset
            else
              leave_balance_on_end = employee_attendances_in_btw.present? ? leave_balance_at_very_next_reset + leave_taken_in_btw_end_and_next_reset - addl_leave_taken_in_btw_end_and_next_reset : nil
            end
          else
            if emp_leave.is_active
              leave_balance_on_end = leave_balance_at_very_next_reset + leave_taken_in_btw_end_and_next_reset - addl_leave_taken_in_btw_end_and_next_reset
            else
              leave_balance_on_end = employee_attendances_in_btw.present? ? leave_balance_at_very_next_reset + leave_taken_in_btw_end_and_next_reset - addl_leave_taken_in_btw_end_and_next_reset : nil
            end
          end
        else
          #Get leave balance from current employee_leave_balance
          emp_leave_taken_after_end = 0.0
          addl_emp_leave_taken_after_end = 0.0
          emp_leave_taken = emp_leave.leave_taken
          emp_leave_count = emp_leave.leave_count
          emp_additional_leaves = emp_leave.additional_leaves
          employee_attendances_btw_end_date_and_current_date = self.employee_attendances.select{|ea| ea.attendance_date > end_date.to_date and ea.attendance_date <= Date.today and ea.employee_leave_type_id == emp_leave.employee_leave_type_id }
          employee_addl_attendances_btw_end_date_and_current_date = self.employee_additional_leaves.select{|eal| eal.attendance_date > end_date.to_date and eal.attendance_date <= Date.today and eal.employee_leave_type_id == emp_leave.employee_leave_type_id }
          if employee_attendances_btw_end_date_and_current_date.compact.present?
            employee_attendances_btw_end_date_and_current_date.each{|ea| emp_leave_taken_after_end += ea.is_half_day ? 0.5 : 1.0}
          end
          if employee_addl_attendances_btw_end_date_and_current_date.compact.present?
            employee_addl_attendances_btw_end_date_and_current_date.each{|ea| addl_emp_leave_taken_after_end += ea.is_half_day ? 0.5 : 1.0}
          end
          if emp_leave.is_additional
            if emp_leave.is_active
              leave_balance_on_end = emp_leave_count - (emp_leave_taken) + (emp_leave_taken_after_end - addl_emp_leave_taken_after_end)
            else
              leave_balance_on_end = employee_attendances_in_btw.present? ? (emp_leave_count - (emp_leave_taken) + (emp_leave_taken_after_end - addl_emp_leave_taken_after_end)) : nil
            end
          else
            if emp_leave.is_active
              leave_balance_on_end = emp_leave_count - (emp_leave_taken) + (emp_leave_taken_after_end - addl_emp_leave_taken_after_end)
            else
              leave_balance_on_end = employee_attendances_in_btw.present? ? (emp_leave_count - (emp_leave_taken) + (emp_leave_taken_after_end - addl_emp_leave_taken_after_end)) : nil
            end
          end
        end
        
        #------------------- Leave Balance On Start Date -------------------------#
        if leave_balance_on_end.present?
          leave_added = 0.0
          employee_leave_balances_btw_start_and_end_date = all_leave_balance_records.select{|elb| elb.reset_date >= start_date.to_date and elb.reset_date <= end_date.to_date and elb.employee_leave_type_id == emp_leave.employee_leave_type_id}
          unless employee_leave_balances_btw_start_and_end_date.compact.present?
            # No Reset Happened in between
            # Get Leave Balance at the end, Leave taken between the date and add both to get leave balance on Start date
            leave_balance_start = leave_balance_on_end + leave_taken_btw_start_and_end_date - addl_leave_taken_btw_start_and_end_date
            #            leave_balance_start = leave_balance_start_1 < 0 ? (leave_balance_on_end + leave_taken_btw_start_and_end_date) : leave_balance_start_1
          else
            # Reset happened in between
            # Get Leave balance at end, Leave taken in between and Leave added during the reset, 
            # then do (Leave Balance - Leave added + Leave taken)
            # employee_leave_balances_btw_start_and_end_date = all_leave_balance_records.select{|elb| elb.reset_date >= start_date.to_date and elb.reset_date <= end_date.to_date and elb.employee_leave_type_id == emp_leave.employee_leave_type_id}
            leave_added = employee_leave_balances_btw_start_and_end_date.collect(&:leaves_added).sum.to_f
            leave_balance_start = leave_balance_on_end - leave_added + leave_taken_btw_start_and_end_date - addl_leave_taken_btw_start_and_end_date
            #            leave_balance_start = leave_balance_start_1 < 0 ? (leave_balance_on_end - leave_added + leave_taken_btw_start_and_end_date) : leave_balance_start_1
          end
          if employee_leave_balances_btw_start_and_end_date.present? and employee_leave_balances_btw_start_and_end_date.last.is_inactivated and employee_attendances_in_btw.present?
            hash_key = type.present? ? "#{employee_leave_type.full_name} \n#{t('inactive')}" : "#{employee_leave_type.full_name} <i>#{t('inactive')}</i>"
          elsif employee_leave_balance_after_end_date.present? and employee_leave_balance_after_end_date.is_inactivated and employee_attendances_in_btw.present?
            hash_key = type.present? ? "#{employee_leave_type.full_name} \n#{t('inactive')}" : "#{employee_leave_type.full_name} <i>#{t('inactive')}</i>"
          elsif emp_leave.is_active == false and employee_attendances_in_btw.present?
            hash_key = type.present? ? "#{employee_leave_type.full_name} \n#{t('inactive')}" : "#{employee_leave_type.full_name} <i>#{t('inactive')}</i>"
          else
            hash_key = employee_leave_type.full_name
          end
          leave_balance_on_start_hash[hash_key] = leave_balance_start
          leave_balance_on_end_hash[hash_key] = addl_leave_taken_btw_start_and_end_date.zero? ? leave_balance_on_end : "#{leave_balance_on_end}(#{addl_leave_taken_btw_start_and_end_date})"
          leave_added_hash[hash_key] = leave_added
          leave_taken_hash[hash_key] = leave_taken_btw_start_and_end_date
        end
        
      else
        leave_balance_on_end_hash[hash_key] = nil
        if emp_leave.reset_date < end_date.to_date
          leave_balance_on_end_hash[hash_key] = emp_leave_count - leave_taken_btw_start_and_end_date
        end
        leave_balance_on_start_hash[hash_key] = nil
        leave_taken_hash[hash_key] = leave_taken_btw_start_and_end_date
        leave_added_hash[hash_key] = nil
      end
    end
    return {:leave_balance_on_end_date_hash => leave_balance_on_end_hash,:leave_balance_on_start_date_hash => leave_balance_on_start_hash,
      :leave_taken_in_between_hash => leave_taken_hash, :leave_added_in_between_hash => leave_added_hash}
  end
  
  def leave_types_of_employee
    leave_types_and_ids = Hash.new
    leave_group = self.leave_group
    if leave_group.present?
      leave_types = leave_group.leave_group_leave_types
      leave_types.each{|leave_type| leave_types_and_ids[leave_type.employee_leave_type_id] = leave_type.employee_leave_type.name if leave_type.employee_leave_type.is_active} if leave_types.present?
    end
    leave_types_and_ids
  end
  
  def self.leave_types_of_employees(employee_ids)
    employees = self.find(employee_ids, :include => {:leave_group => :leave_group_leave_types})
    leave_types_and_ids = Hash.new
    employee_leave_type_id = []
    employees.each do |employee|
      leave_group = employee.leave_group
      employee_leave_type_id << leave_group.leave_group_leave_types.collect(&:employee_leave_type_id) if leave_group.present?
    end
    employee_leave_type_id = employee_leave_type_id.flatten.uniq
    if employee_leave_type_id.present?
      leave_types = EmployeeLeaveType.find_all_by_id(employee_leave_type_id, :select => "id, name,is_active") 
      leave_types.each{|leave_type| leave_types_and_ids[leave_type.id] = leave_type.name if leave_type.is_active } if leave_types.present?
    end
    leave_types_and_ids
  end
  
  def self.leave_type_names(employee_id, leave_type_ids)
    leave_type_names = []
    employee = self.find(employee_id, :include => {:leave_group => :leave_group_leave_types})
    if employee.present? and leave_type_ids.present?
      leave_group = employee.leave_group
      if leave_group.present?
        leave_group_types = leave_group.leave_group_leave_types.find_all_by_employee_leave_type_id(leave_type_ids)
        leave_group_types.each{|type| leave_type_names << type.employee_leave_type.name} if leave_group_types.present?
      end
    end
    leave_type_names.flatten.uniq.join(", ")
  end
end