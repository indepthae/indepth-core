class EmployeePayslip < ActiveRecord::Base
  xss_terminate

  attr_accessor :mode, :additional_leaves, :regenerate, :audit_check, :is_regeneration
  belongs_to :employee, :polymorphic => true
  has_one :archived_employee, :foreign_key => :former_id, :primary_key => :employee_id
  belongs_to :payroll_group
  has_many :employee_payslip_categories, :dependent => :destroy
  has_many :individual_payslip_categories, :dependent => :destroy
  has_many :payslip_additional_leaves, :dependent => :destroy
  belongs_to :approver ,:class_name => 'User'
  belongs_to :rejector ,:class_name => 'User'
  belongs_to :finance_transaction, :dependent => :destroy
  belongs_to :payslips_date_range
  belongs_to :payroll_revision
  belongs_to :financial_year
  
  serialize :employee_details, Hash
  serialize :leave_details, Hash

  validates_presence_of :gross_salary, :net_pay, :employee_id
  validates_presence_of :days_count, :if => "lop.present?"
  validates_presence_of :reason, :if => "is_rejected and (is_rejected_was != is_rejected)"
  validates_presence_of :additional_leaves, :if => lambda{|p| p.new_record? and p.days_count.present? and p.days_count.to_f > 0}
  validates_numericality_of :gross_salary, :greater_than_or_equal_to => 0
  validates_numericality_of :net_pay, :greater_than_or_equal_to => 0
  #  validates_uniqueness_of :payslips_date_range_id, :scope => [:employee_id, :employee_type], :message => :payslip_has_been_already_generated

  accepts_nested_attributes_for :employee_payslip_categories
  accepts_nested_attributes_for :individual_payslip_categories, :allow_destroy => true
  accepts_nested_attributes_for :payslip_additional_leaves, :allow_destroy => true

  named_scope :individual_employee_payslips, {:select => "employee_payslips.id, employee_payslips.net_pay, employee_payslips.is_approved, employee_payslips.is_rejected, employee_payslips.payslips_date_range_id, payslips_date_ranges.start_date, payslips_date_ranges.end_date, YEAR(payslips_date_ranges.start_date) AS year", :joins => :payslips_date_range, :order => 'year desc, payslips_date_ranges.start_date desc'}
  named_scope :approved_payslips ,{:conditions => "is_approved = true"}
  named_scope :pending_payslips, {:conditions => "is_approved = false AND is_rejected = false"}
  named_scope :rejected_payslips, {:conditions => "is_rejected = true"}
  named_scope :approved_and_pending_payslips, {:conditions => "is_rejected = false"}
  named_scope :pending_and_rejected_payslips, {:conditions => "employee_payslips.is_approved = false"}
  named_scope :total_yearly_cost, {:select => "SUM(employee_payslips.net_pay) AS cost, YEAR(payslips_date_ranges.start_date) AS year", :joins => :payslips_date_range, :order => 'year desc, payslips_date_ranges.start_date', :group => "year"}
  named_scope :group_wise_payslips, lambda{|start_date, end_date, pg_id, where_condition| {:select =>"employee_payslips.id, employee_payslips.employee_id, employee_payslips.employee_type, emp.first_name, emp.employee_number, emp.middle_name, emp.last_name, employee_departments.name AS dept_name, employee_payslips.is_approved, employee_payslips.is_rejected, employee_payslips.net_pay, employee_payslips.lop, employee_payslips.days_count, payslips_date_ranges.revision_number = employee_payslips.revision_number AS current_group, employee_payslips.deducted_from_categories", :joins => "INNER JOIN payslips_date_ranges ON payslips_date_ranges.id = employee_payslips.payslips_date_range_id INNER JOIN ((SELECT id AS emp_id, first_name, last_name, middle_name, employee_number, employee_department_id, 'Employee' AS emp_type from employees #{where_condition}) UNION ALL (SELECT id AS emp_id,first_name, last_name, middle_name, employee_number, employee_department_id, 'ArchivedEmployee' AS emp_type from archived_employees #{where_condition})) emp ON emp.emp_id=employee_payslips.employee_id AND employee_type = emp_type INNER JOIN employee_departments ON employee_departments.id = emp.employee_department_id", :conditions => ["payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ? AND payslips_date_ranges.payroll_group_id = ?", start_date, end_date, pg_id], :order => "emp.first_name"}} do
    def status
      select_query =%q{
          count(employee_payslips.id) as total,
          count(if(employee_payslips.is_approved=1,1,null)) as approved,
          count(if(employee_payslips.is_rejected=1,1,null)) as rejected,
          count(if(employee_payslips.is_rejected=0 and employee_payslips.is_approved=0,1,null)) as pending,
          count(if(payslips_date_ranges.revision_number <> employee_payslips.revision_number,1,null)) as outdated,
          count(if(payslips_date_ranges.revision_number = employee_payslips.revision_number and employee_payslips.is_rejected = 0,1,null)) as normal_employees
      }
      proxy_scope.first(proxy_options.merge(:select=>select_query))
    end

  end
  named_scope :updated_structure_payslips, :conditions => "payslips_date_ranges.revision_number = employee_payslips.revision_number"
  named_scope :outdated_structure_payslips, :conditions => "payslips_date_ranges.revision_number <> employee_payslips.revision_number"
  named_scope :load_payslips_categories, :include => [:employee_payslip_categories, :individual_payslip_categories, {:payslip_additional_leaves => :employee_additional_leave}]
  named_scope :with_lop, :conditions => ["employee_payslips.days_count IS NOT NULL or employee_payslips.days_count != ?",'0']
  named_scope :without_lop, :conditions => ["employee_payslips.days_count IS NULL or employee_payslips.days_count =  ?",'0']

  validate :check_date_ranges
  before_update :approve_reject_validation
  before_validation :create_payslip_additional_leaves
  before_validation :calculate_net_pay
  before_create :calculate_lop_amount
  before_create :delete_old_record
  before_create :set_financial_year
  after_create :save_employee_details_and_footnote
  before_save :save_employee_details_and_footnote, :on => :update, :if => :is_regeneration

  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end

  include CsvExportMod

  PAYSLIP_STATUS = {1 => "pending", 2 => "approved", 3 => "rejected"}
  
  def date_range
    payslip_date_range = self.payslips_date_range
    pg = payslip_date_range.payroll_group
    if pg.payment_period == 5
      return format_date(payslip_date_range.start_date,:format => :month_year)
    elsif pg.payment_period == 1
      return format_date(payslip_date_range.start_date)
    else
      return format_date(payslip_date_range.start_date) + " - " + format_date(payslip_date_range.end_date)
    end
  end

  def check_date_ranges
    if self.new_record? and payslips_date_range.present?
      end_date = payslips_date_range.end_date
      employee = Employee.find employee_id
      self.errors.add_to_base("Payslip before joining date") if employee.joining_date > end_date
      unless employee.employee_salary_structure.payroll_group_id == payslips_date_range.payroll_group_id
        self.errors.add_to_base("Invalid payroll group")
      end
    end
  end

  def calculate_net_pay
    unless changed.include? 'is_approved' or changed.include? "finance_transaction_id"
      total_earnings = self.earning_categories.map{|cat| FedenaPrecision.set_and_modify_precision cat.amount}.map(&:to_f).sum
      total_earnings += self.individual_earnings_total
      total_deductions = self.deduction_categories.map{|cat| FedenaPrecision.set_and_modify_precision cat.amount}.map(&:to_f).sum
      total_deductions += self.individual_deductions_total
      if self.lop.present?
        self.lop = FedenaPrecision.set_and_modify_precision lop
        total_deductions += self.lop.to_f
      end
      self.total_earnings = FedenaPrecision.set_and_modify_precision(total_earnings)
      self.total_deductions = FedenaPrecision.set_and_modify_precision(total_deductions)
      self.net_pay =  FedenaPrecision.set_and_modify_precision(PayrollGroup.rounding_up((total_earnings - total_deductions),Configuration.get_rounding_off_value.config_value.to_i))
      self.gross_salary = FedenaPrecision.set_and_modify_precision gross_salary
    end
  end

  def calculate_lop_amount
    cache_key = employee.get_lop_cache_key
    if Rails.cache.exist?(cache_key)
      lop_per_day = Rails.cache.fetch(cache_key)
      lop_per_day = (lop_per_day == :nil ? nil : lop_per_day)
    else
      lop_per_day = self.employee.employee_salary_structure.calculate_lop
      Rails.cache.fetch(cache_key){ lop_per_day||:nil }
    end
    self.lop_amount = FedenaPrecision.set_and_modify_precision(lop_per_day)
    payment_period = payslips_date_range.payroll_group.payment_period
    self.working_days = SalaryWorkingDay.get_working_days(payment_period,payslips_date_range.start_date.month)
  end
  
  def delete_old_record
    if regenerate.present?
      date_range = payslips_date_range
      payslip = employee.employee_payslips.first(:joins => :payslips_date_range, :conditions => ["payslips_date_ranges.start_date = ? AND payslips_date_ranges.end_date = ?", date_range.start_date, date_range.end_date])  
      payslip.destroy if payslip.present?
    end
  end

  def approve_reject_validation
    old_is_approved = self.is_approved_was
    old_is_rejected = self.is_rejected_was
    is_approved = self.is_approved
    is_rejected = self.is_rejected
    changes = self.changes
    if changes.present?
      if changes.include? 'is_approved'
        if !old_is_approved and is_approved
          return false if old_is_approved or old_is_rejected or lop_leaves_validation
        end
        if old_is_approved and !is_approved
          return false unless old_is_approved and !is_approved
        end
      end
      if changes.include? 'is_rejected'
        if !old_is_rejected and is_rejected
          return false if old_is_approved or old_is_rejected
        end
        if old_is_rejected and !is_rejected
          return false unless self.mode == 'edit'
        end
      end
    else
      return false
    end
  end


  def validate
    if employee_type == 'ArchivedEmployee'
      employee = ArchivedEmployee.find_by_id(employee_id)
    else
      employee = Employee.find_by_id(employee_id)
    end
    if employee.present?
      self.employee = employee
    else
      errors.add(:employee_id, :invalid)
    end
  end

  def create_payslip_additional_leaves
    add_leaves = self.additional_leaves
    if add_leaves.present?
      self.payslip_additional_leaves.destroy_all
      add_leaves = add_leaves.split(",")
      add_leaves.each do |l|
        additional_leave = EmployeeAdditionalLeave.find_by_id l
        if additional_leave.present?
          self.payslip_additional_leaves.build(:employee_additional_leave_id => additional_leave.id, :attendance_date => additional_leave.attendance_date, :is_half_day => additional_leave.is_half_day)
        else
          return false
        end
      end
    else
      if self.payslip_additional_leaves.present? and self.mode == 'edit'
        self.payslip_additional_leaves.destroy_all
        self.lop = nil
      end
    end
  end 
    
  #method to fetch attendance records
  def method_missing(m, *args, &block)
    #m = code example: "CL"
    leave_type = EmployeeLeaveType.active.first(:conditions=>{:code=>m.to_s})
    if leave_type.present?
      count = if self.leave_details.present?
        self.leave_details[m.to_s].to_s.to_i
      else
        employee.employee_attendances.count(:conditions => ["employee_leave_type_id = ? AND attendance_date between ? AND ?", 
            leave_type.id, payslips_date_range.start_date, payslips_date_range.end_date])
      end
      return count
    elsif ["no_of_days_present", "total_leave"].include? m.to_s
      count = get_leave_count(m)
      return count
    end
    super
  end
  
  def get_leave_count(type)
    if self.leave_details.present? and self.leave_details[type.to_s].present?
      self.leave_details[type.to_s].to_s.to_i
    else
      total_count = employee.employee_attendances.count(:conditions => ["attendance_date between ? AND ?", 
          payslips_date_range.start_date, payslips_date_range.end_date])
      total_count = self.working_days.to_i - total_count if type.to_s == "no_of_days_present"
      return total_count
    end
  end
  
  def save_employee_details_and_footnote    
    employee = self.employee || ArchivedEmployee.find_by_former_id(self.employee_id)
    details = employee.employee_settings(self.id)
    details = { "employee_details" => details, "footnote" => PayslipSetting.footnote }
    self.employee_details = details
    self.leave_details = employee.leave_details(self.id)
    self.send(:update_without_callbacks)
  end  

  def self.save_payslips(payslips,start_date,end_date, payroll_group_id)
    payroll_group = PayrollGroup.find(payroll_group_id, :include => :payroll_categories)
    payslip_date_range = PayslipsDateRange.find_by_start_date_and_end_date_and_payroll_group_id(start_date.to_date,end_date.to_date, payroll_group_id)
    if payslip_date_range.present?
      payslip_date_range.update_attributes(:revision_number => payroll_group.current_revision, :generation_type => 'bulk')
    else
      payslip_date_range = PayslipsDateRange.create(:start_date => start_date.to_date, :end_date => end_date.to_date, :payroll_group_id => payroll_group_id, :revision_number => payroll_group.current_revision, :generation_type => 'bulk')
    end
    earnings = payroll_group.earnings_list
    deductions = payroll_group.deductions_list
    payslips.each do |payslip|
      emp_id = payslip["emp_id"].to_i
      if payslip["status"] == true && payslip["checked"] == 1 && payslip["error"] == 0
        earning_sum = 0
        deduction_sum = 0
        values = {:employee_id => emp_id, :employee_type => 'Employee', :net_pay => 0, :gross_salary => 0, :revision_number => payroll_group.current_revision, :payroll_revision_id => payslip["lat_rev_id"]}
        emp_payslip = payslip_date_range.employee_payslips.new(values)
        earnings.each do |ear|
          val = payslip["earnings"][ear.id.to_s]
          if val.present?
            cat = {:payroll_category_id => ear.id, :amount => val[1], :is_deduction => 0}
            earning_sum+= val[1].to_f
            emp_payslip.employee_payslip_categories.build(cat)
          end
        end
        deductions.each do |ded|
          val = payslip["deductions"][ded.id.to_s]
          if val.present?
            cat = {:payroll_category_id => ded.id, :amount => val[1], :is_deduction => 1}
            deduction_sum+= val[1].to_f
            emp_payslip.employee_payslip_categories.build(cat)
          end
        end
        payslip["individual_earnings"].each do |key,val|
          cat = {:name => val[0], :amount => val[1], :is_deduction => 0}
          earning_sum+= val[1].to_f
          emp_payslip.individual_payslip_categories.build(cat)
        end

        payslip["individual_deductions"].each do |key,val|
          cat = {:name => val[0], :amount => val[1], :is_deduction => 1}
          deduction_sum+= val[1].to_f
          emp_payslip.individual_payslip_categories.build(cat)
        end

        emp_payslip.net_pay = earning_sum - deduction_sum
        emp_payslip.gross_salary = earning_sum

        unless emp_payslip.save
          payslip["status"] = true
          payslip["checked"] = 1
          payslip["error"] = 1
          payslip["saved"] = 0
          payslip["error_msg"] = emp_payslip.errors.full_messages.join(",")
        else
          payslip["status"] = false
          payslip["checked"] = 0
          payslip["error"] = 0
          payslip["saved"] = 1
        end

      end
    end
    return payslips
  end

  def self.fetch_conditions(query_hash={})
    conditions = []
    values = []
    unless query_hash[:department_id] == "All"
      conditions << "emp.employee_department_id = ?"
      values << query_hash[:department_id]
    end
    conditions << "payslips_date_ranges.start_date BETWEEN ? AND ?"
    values += ["#{query_hash[:start_date]}", "#{query_hash[:end_date]}"]
    unless query_hash[:payslip_period] == "All"
      conditions << "payroll_groups.payment_period = ?"
      values << query_hash[:payslip_period]
    end
    unless query_hash[:payslip_status] == "All"
      case query_hash[:payslip_status].to_i
      when 1
        conditions << "employee_payslips.is_approved = false AND employee_payslips.is_rejected = false"
      when 2
        conditions << "employee_payslips.is_approved = true"
      when 3
        conditions << "employee_payslips.is_rejected = true"
      end
    end
    if query_hash[:employee_name].present?
      conditions << "emp.first_name LIKE ? OR emp.middle_name LIKE ? OR emp.last_name LIKE ?"
      values += ["%#{query_hash[:employee_name]}%", "%#{query_hash[:employee_name]}%", "%#{query_hash[:employee_name]}%"]
    end
    if query_hash[:employee_no].present?
      conditions << "emp.employee_number = ?"
      values << "#{query_hash[:employee_no]}"
    end
    return [conditions.join(" AND ")] + values
  end

  def payslip_status
    self.is_rejected == true ? t('rejected') : self.is_approved == true ? t('approved') : t('pending')
  end

  def earning_categories
    if self.new_record?
      self.employee_payslip_categories.select{|c| c.is_deduction.to_i == 0}
    else
      self.employee_payslip_categories.select{|c| !c.payroll_category.is_deduction}
    end
  end

  def deduction_categories
    if self.new_record?
      self.employee_payslip_categories.select{|c| c.is_deduction.to_i == 1}
    else
      self.employee_payslip_categories.select{|c| c.payroll_category.is_deduction}
    end
  end

  def individual_earnings
    self.individual_payslip_categories.select{|e| !e.is_deduction}
  end

  def individual_deductions
    self.individual_payslip_categories.select{|e| e.is_deduction}
  end

  def individual_earnings_total
    categories = individual_payslip_categories.select{|k| !k.marked_for_destruction?}
    categories.select{|i| !i.is_deduction}.inject(0){|res,ele| res + FedenaPrecision.set_and_modify_precision(ele.amount).to_f}
  end

  def individual_deductions_total
    categories = individual_payslip_categories.select{|k| !k.marked_for_destruction?}
    categories.select{|i| i.is_deduction}.inject(0){|res,ele| res + FedenaPrecision.set_and_modify_precision(ele.amount).to_f}
  end

  def individual_earnings_list
    individual_payslip_categories.select{|c| !c.is_deduction}.each_with_object({}){|c, hsh| hsh[c.name] = c.amount}
  end

  def individual_deductions_list
    individual_payslip_categories.select{|c| c.is_deduction}.each_with_object({}){|c, hsh| hsh[c.name] = c.amount}
  end

  def reject_payslip(user, reason)
    if self.update_attributes({:is_rejected => true, :rejector_id => user.id, :reason => reason})
      privilege = Privilege.find_by_name("PayrollAndPayslip")
      hr_ids = privilege.user_ids
      name = self.employee.last_name.present? ? self.employee.first_name : "#{self.employee.first_name} #{self.employee.last_name}"
      body = "#{t('payslip_rejected_for')} "+ name + " (#{t('employee_number')} : #{self.employee.employee_number})" +" #{t('for_the_payslip_date_range_from')} #{format_date(self.payslips_date_range.start_date, :short)} #{t('to_text')} #{format_date(self.payslips_date_range.end_date, :short)}"
      #      Delayed::Job.enqueue(DelayedReminderJob.new(:sender_id => user.id,
      #          :recipient_ids => hr_ids,
      #          :subject => subject,
      #          :body => body))
      links = {:target=>'view_rejected_payslip'}
      inform(hr_ids,body,'HR',links)
    end
  end

  def lop_leaves_errors
    add_leaves = payslip_additional_leaves
    cond = (add_leaves.present? and !is_approved_was)
    errors, deducted, removed, non_deductable, type_changed = Array.new(5) { [] }
    if cond
      add_leaves.each do |l|
        emp_add_leave = l.employee_additional_leave
        unless emp_add_leave.nil?
          deducted << l.attendance_date if emp_add_leave.is_deducted
          non_deductable << l.attendance_date unless emp_add_leave.is_deductable
          type_changed << l.attendance_date unless emp_add_leave.is_half_day == l.is_half_day
        else
          removed << l.attendance_date
        end
      end
      errors << t('lop_leave_not_present', {:dates => removed.map{|d| format_date(d).strip}.join(", ")}) if removed.present?
      errors << t('lop_already_deducted', {:dates => deducted.map{|d| format_date(d).strip}.join(", ")}) if deducted.present?
      errors << t('lop_status_updated', {:dates => non_deductable.map{|d| format_date(d).strip}.join(", ")}) if non_deductable.present?
      errors << t('lop_leave_type_has_updated', {:dates => type_changed.map{|d| format_date(d).strip}.join(", ")}) if type_changed.present?
    end
    return errors
  end

  def lop_leaves_validation
    lop_leaves_errors.present?
  end

  def all_additional_leave
    additional_leaves = EmployeeAdditionalLeave.employee_additional_leaves(employee_id)
    add_leaves = payslip_additional_leaves.all(:select => "employee_additional_leaves.*, employee_leave_types.name AS name", :joins => {:employee_additional_leave => :employee_leave_type})
    if add_leaves.present?
      add_leaves.each do |l|
        additional_leaves << l unless additional_leaves.collect(&:id).include? l.id or l.is_deducted
      end
    end
    return additional_leaves
  end

  def build_payslip_categories(employee)
    salary_structure = employee.employee_salary_structure
    salary_structure.earning_components.each do |comp|
      self.employee_payslip_categories.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount, :pc_name => comp.payroll_category.name, :pc_code => comp.payroll_category.code, :is_deduction => (comp.payroll_category.is_deduction ? 1 : 0))
    end
    salary_structure.deduction_components.each do |comp|
      self.employee_payslip_categories.build(:payroll_category_id => comp.payroll_category_id, :amount => comp.amount, :pc_name => comp.payroll_category.name, :pc_code => comp.payroll_category.code, :is_deduction => (comp.payroll_category.is_deduction ? 1 : 0))
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def get_additional_detail_value(columns)
    additional_details = if employee_type == 'Employee'
      employee.employee_additional_details
    else
      employee.archived_employee_additional_details
    end
    details = {}
    additional_details.each{|det| details["additional_detail_#{det.additional_field_id}"] = det.additional_info }
    columns.each{|col| self[col] = (details[col]||"-")}
  end

  def get_bank_detail_value(columns)
    bank_details = if employee_type == 'Employee'
      employee.employee_bank_details
    else
      employee.archived_employee_bank_details
    end
    details = {}
    bank_details.each{|det| details["bank_detail_#{det.bank_field_id}"] = det.bank_info }
    columns.each{|col| self[col] = (details[col]||"-")}
  end

  def get_payroll_category_value(columns)
    payslip_categories = employee_payslip_categories
    details = {}
    payslip_categories.each{|det| details["payroll_category_#{det.payroll_category_id}"] = det.amount }
    columns.each{|col| self[col] = (details[col]||"-")}
  end

  def date_range_text
    date_range
  end

  def other_earnings
    content = ""
    individual_earnings.each do |ear|
      content += "<div class='field'><div class='field-name'>#{ear.name}</div><div class='field-value'>#{ear.amount}</div></div>"
    end
    content
  end

  def other_deductions
    content = ""
    individual_deductions.each do |ded|
      content += "<div class='field'><div class='field-name'>#{ded.name}</div><div class='field-value'>#{ded.amount}</div></div>"
    end
    content
  end

  def other_earnings_csv
    content = ""
    individual_earnings.each do |ear|
      content += "#{ear.name} - #{ear.amount}\n"
    end
    content
  end

  def other_deductions_csv
    content = ""
    individual_deductions.each do |ded|
      content += "#{ded.name} - #{ded.amount}\n"
    end
    content
  end

  def salary_summary
    content = "<div class='field'><div class='field-name'>#{t('earnings')}</div></div>"
    earning_categories.each do |ear|
      content += "<div class='field'><div class='field-name'>#{ear.payroll_category.name}</div><div class='field-value'>#{ear.amount}</div></div>"
    end
    individual_earnings.each do |ear|
      content += "<div class='field'><div class='field-name'>#{ear.name}</div><div class='field-value'>#{ear.amount}</div></div>"
    end
    content += "<div class='field'><div class='field-name'>#{t('deductions')}</div></div>"
    deduction_categories.each do |ded|
      content += "<div class='field'><div class='field-name'>#{ded.payroll_category.name}</div><div class='field-value'>#{ded.amount}</div></div>"
    end
    content += "<div class='field'><div class='field-name'>#{t('lop')}</div><div class='field-value'>#{lop}</div></div>" if lop.present?
    individual_earnings.each do |ear|
      content += "<div class='field'><div class='field-name'>#{ear.name}</div><div class='field-value'>#{ear.amount}</div></div>"
    end
    content
  end
  
  def salary_summary_csv
    content = "#{t('earnings')}\n"
    earning_categories.each do |ear|
      content += "#{ear.payroll_category.name} - #{ear.amount}\n"
    end
    individual_earnings.each do |ear|
      content += "#{ear.name} - #{ear.amount}\n"
    end
    content += "#{t('deductions')}\n"
    deduction_categories.each do |ded|
      content += "#{ded.payroll_category.name} - #{ded.amount}\n"
    end
    individual_earnings.each do |ear|
      content += "#{ear.name} - #{ear.amount}\n"
    end
    content
  end

  def no_of_lop
    days_count
  end

  def no_of_working_days
    working_days
  end
   
  class << self
    def approve_payslips(ids, user)
      cat_id = FinanceTransactionCategory.find_by_name('Salary').id
      payslips = EmployeePayslip.find(ids, :include => [:employee, :payslips_date_range])
      count = 0
      payslips.each do |payslip|
        errors = false
        ActiveRecord::Base.transaction do
          if payslip.update_attributes({:is_approved => true, :approver_id => user.id})
            finance_transaction=FinanceTransaction.new(
              :title => "Monthly Salary",
              :description => "Salary of #{payslip.employee.employee_number} for the payslip date range from #{format_date(payslip.payslips_date_range.start_date)} to #{format_date(payslip.payslips_date_range.end_date)}",
              :amount => payslip.net_pay,
              :category_id => cat_id,
              :transaction_date => Date.today,
              :payee => payslip.employee,
              :finance => payslip
            )
            errors = true unless finance_transaction.save
            payslip.audit_check = true
            errors = true unless payslip.update_attributes(:finance_transaction_id=>finance_transaction.id)
            EmployeeAdditionalLeave.update_all({:is_deducted => true}, ["id IN (?)", payslip.payslip_additional_leaves.collect(&:employee_additional_leave_id)]) if payslip.payslip_additional_leaves.present? and !errors
            count += 1 unless errors
            notify_approval(payslip) unless errors
          else
            payslip.errors.full_messages
          end
          raise ActiveRecord::Rollback if errors
        end
      end
      return count
    end
    
    def notify_approval(payslip)
      body = t("your_payslip_approved",:date_range=>payslip.date_range_text)
      links = {:target=>'view_payslip',:target_value=>payslip.id}
      inform([payslip.employee.user_id],body,'HR',links)
    end

    def revert_payslips(ids)
      payslips = EmployeePayslip.find(ids)
      count = 0
      payslips.each do |payslip|
        errors = false
        ActiveRecord::Base.transaction do
          transaction = payslip.finance_transaction
          if payslip.employee_type == 'Employee'
            if payslip.update_attributes({:is_approved => false, :is_rejected => false, :approver_id => nil, :finance_transaction_id => nil})
              EmployeeAdditionalLeave.update_all("is_deducted = 0", ["id in (?)", payslip.payslip_additional_leaves.collect(&:employee_additional_leave_id)]) if payslip.payslip_additional_leaves.present? and !errors
              errors = true unless transaction.destroy
              count += 1 unless errors
            end
          else
            if payslip.destroy
              EmployeeAdditionalLeave.update_all("is_deducted = 0", ["id in (?)", payslip.payslip_additional_leaves.collect(&:employee_additional_leave_id)]) if payslip.payslip_additional_leaves.present?
              count += 1
            end
          end
          raise ActiveRecord::Rollback if errors
        end
      end
      return count
    end

    def revert_pending_payslips(ids)
      payslips = EmployeePayslip.find(ids)
      count = 0
      payslips.each do |payslip|
        unless payslip.is_approved
          count += 1 if payslip.destroy
        end
      end
      return count
    end

    def fetch_group_wise_employee_payslips_data(params)
      group_wise_employee_payslips_data(params)
    end

    def get_payslip_categories(id)
      payslip = find(id)
      emp_type = payslip.employee_type
      employee_payslip = if emp_type == "Employee"
        find(id, :include =>  {:employee => [:employee_department, :employee_grade, :employee_category, :employee_bank_details], :archived_employee => [:employee_department, :employee_grade, :employee_category, :archived_employee_bank_details], :employee_payslip_categories => :payroll_category})
      else
        find(id,:include =>  {:archived_employee => [:employee_department, :employee_grade, :employee_category, :archived_employee_bank_details], :employee_payslip_categories => :payroll_category})
      end
      individual_categories = employee_payslip.individual_payslip_categories
      payroll_rev = payslip.payroll_revision.payroll_details if payslip.deducted_from_categories and payslip.payroll_revision.present?
      earnings = if payroll_rev.present?
        employee_payslip.employee_payslip_categories.select{|cat| !cat.payroll_category.is_deduction and (cat.amount.to_f > 0 or payroll_rev["salary_components"][cat.payroll_category_id].to_f > 0)}
      else
        employee_payslip.employee_payslip_categories.select{|cat| !cat.payroll_category.is_deduction and cat.amount.to_f > 0}
      end
      deductions = if payroll_rev.present? 
        employee_payslip.employee_payslip_categories.select{|cat| cat.payroll_category.is_deduction and (cat.amount.to_f > 0 or payroll_rev["salary_components"][cat.payroll_category_id].to_f > 0)}
      else
        employee_payslip.employee_payslip_categories.select{|cat| cat.payroll_category.is_deduction and cat.amount.to_f > 0}
      end
      ind_earnings = individual_categories.select{|cat| !cat.is_deduction and cat.amount.to_f > 0}
      ind_deductions = individual_categories.select{|cat| cat.is_deduction and cat.amount.to_f > 0}
      lop_present = employee_payslip.lop.present?
      max_length = [(earnings.length + ind_earnings.length), (deductions.length + ind_deductions.length + (lop_present ? 1 : 0))].max
      all_categories = []
      ind_ear_index = ind_ded_index = 0
      (0..(max_length - 1)).each do |l|
        ear = earnings[l]
        ded = deductions[l]
        row = []
        if ear.present?
          pay_amount = payroll_rev["salary_components"][ear.payroll_category_id] if payroll_rev.present?
          row << {:category => ear.payroll_category.name, :amount => ear.amount, :pay_amount => pay_amount}
        else
          ind_ear = ind_earnings[ind_ear_index]
          if ind_ear.present?
            row << {:category => ind_ear.name, :amount => ind_ear.amount, :pay_amount => "-"}
            ind_ear_index += 1
          else
            row << {}
          end
        end
        if ded.present?
          pay_amount = payroll_rev["salary_components"][ded.payroll_category_id] if payroll_rev.present?
          row << {:category => ded.payroll_category.name, :amount => ded.amount, :pay_amount => pay_amount}
        else
          unless lop_present
            ind_ded = ind_deductions[ind_ded_index]
            if ind_ded.present?
              row << {:category => ind_ded.name, :amount => ind_ded.amount, :pay_amount => "-"}
              ind_ded_index += 1
            else
              row << {}
            end
          else
            row << {:category => t('loss_of_pay'), :amount => employee_payslip.lop, :pay_amount => "-"}
            lop_present = false
          end
        end
        all_categories << row
      end
      return all_categories
    end
  end
end