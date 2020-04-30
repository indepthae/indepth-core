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

class EmployeeLeaveType < ActiveRecord::Base
  xss_terminate
  
  has_many :employee_leaves, :dependent => :destroy
  has_many :employee_leave_balances, :dependent => :destroy
  has_many :employee_attendances
  has_many :leave_group_leave_types, :dependent => :destroy
  has_many :leave_groups, :through => :leave_group_leave_types
  has_many :leave_credit_slabs
  validates_presence_of :name,:message => :enter_a_leave_name
  validates_presence_of :code,:message => :enter_a_leave_code
  validates_presence_of :credit_frequency,:if => :validate_leave_reset,:message => :select_credit_frequency
  validates_presence_of :creation_status
  validates_presence_of :days_count, :if => Proc.new{|l| l.credit_frequency == 1},:message => :enter_no_of_days
  validates_presence_of :credit_type, :if => Proc.new{|l| l.credit_frequency == 2 or l.credit_frequency == 3 or l.credit_frequency == 4},:message => :enter_credit_type
  validates_uniqueness_of :name,:case_sensitive => false, :message => :leave_name_already_in_use
  validates_uniqueness_of :code,:case_sensitive => false, :message => :leave_code_already_in_use
  validates_length_of :name, :maximum => 80
  validates_length_of :code, :maximum => 20

  validates_numericality_of :max_leave_count, :greater_than_or_equal_to => 0,  :if => Proc.new{|l| l.credit_type == 'Flat' or l.credit_frequency == 1 or l.credit_frequency == 5 } ,:message => :leave_count_must_be_a_number
  validates_numericality_of :max_carry_forward_leaves, :greater_than => 0, :if => "carry_forward_type == 2 && carry_forward", :message => :enter_maximum_leaves_carry_forwarded, :allow_blank => false

  
  # validates_presence_of :max_carry_forward_leaves, :if => "carry_forward_type == 2 && carry_forward"

  before_validation :strip_leading_spaces
  validate :valid_reset_date 
  validate :validate_slab_values, :if => Proc.new{|l| l.credit_type == "Slab"}
  before_save :reset_days_count
  after_save  :build_credit_slab_data , :if => Proc.new{|l| l.credit_type == "Slab"}
  before_destroy :destroy_slab_data ,:if => Proc.new{|l| l.credit_type == "Slab"}
  accepts_nested_attributes_for :leave_credit_slabs, :allow_destroy=>true 
  attr_accessor :slab_values
  named_scope :active,:conditions => {:is_active => true, :creation_status => 2}
  named_scope :inactive,:conditions => {:is_active=> false, :creation_status => 2}
  named_scope :all_leave_types, :conditions => {:creation_status => 2}
  before_create :update_leave_count
  before_update  :update_leave_count
  
  
  def update_leave_count
    self.max_leave_count = nil  if self.credit_type == 'Slab' and self.credit_frequency != 1 and self.credit_frequency != 5
    self.credit_type = nil  if self.credit_type == 'Slab' and (self.credit_frequency == 1 or self.credit_frequency == 5)
  end
  
  def validate_leave_reset
    config = Configuration.get_config_value('LeaveResetSettings') || "0"
    return true if config == '1'
    return false if config == '0'
  end
  
  def validate_slab_values
    hash_data = self.slab_values
    if hash_data.present?
      error =[]
      hash_count = hash_data.count
      (1..hash_count).each do |n|
        val = hash_data["leave_count(#{EmployeeLeaveType.month_name(n).downcase})"] if hash_count == 12  #monthly
        val = hash_data["leave_count(#{EmployeeLeaveType.quarter_name(n).downcase})"] if hash_count == 4 #quarterly
        val = hash_data["leave_count(#{EmployeeLeaveType.year_part(n).downcase})"] if hash_count == 2 #half-yearly
        error << val if val == "" or val == nil
        error <<  val unless is_integer?(val)
      end
      errors.add(:credit_type, :slab_data_vaildate_msg) if error.present?
    end
  end
  
  def is_integer?(val)
    val.to_s.match(/\A[+-]?\d+?(\.\d+)?\Z/) == nil ? false : true
  end

  def self.quarter_name(quarter)
    if quarter == 1
      return "quarter1"
    elsif quarter == 2
      return "quarter2"
    elsif quarter == 3
      return "quarter3"
    elsif quarter == 4
      return "quarter4"
    end
  end

  def self.year_part(part)
    if part == 1
      return "half1"
    elsif part == 2
      return "half2"
    end 
  end
  
  def strip_leading_spaces
    self.name = self.name.strip
    self.code = self.code.strip
  end

  def valid_reset_date
    if reset_date.present? && (reset_date > Date.today)
      errors.add(:reset_date, :reset_date_cannot_be_future_date)
    end

    unless max_leave_count.to_f%0.5 == 0.0 
      errors.add(:max_leave_count, :leave_count_as_whole_numbers)
    end

    unless max_carry_forward_leaves.to_f%0.5 == 0.0
      errors.add(:max_carry_forward_leaves, :leave_count_as_whole_numbers)
    end
  end
  
  def name_with_code
    "#{name} &#x200E;(#{code})&#x200E;"
  end
  
  def full_name
    return ("#{name} (#{code})")
  end
  
  def reset_days_count
    self.days_count = nil unless credit_frequency == 1
  end
  
  def destroy_slab_data
    slab_data = LeaveCreditSlab.find_all_by_employee_leave_type_id(id)
    slab_data_ids = slab_data.collect(&:id)
    return true if LeaveCreditSlab.destroy(slab_data_ids)
  end
  
  def build_credit_slab_data
    hash_data = self.slab_values
    build_arr = {}
    credit_frequency_hash = { :monthly => 2, :quarterly => 3, :half_yearly => 4}
    if credit_frequency == credit_frequency_hash[:monthly]
      EmployeeLeaveType.monthly_credit_slab_data(build_arr, id,hash_data)
    elsif  credit_frequency == credit_frequency_hash[:quarterly]
      EmployeeLeaveType.quarter_credit_slab_data(build_arr, id, hash_data)
    elsif credit_frequency == credit_frequency_hash[:half_yearly]
      EmployeeLeaveType.half_yearly_credit_slab_data(build_arr, id, hash_data)
    end
    return  errors if errors.present?
    return true unless errors.present?
  end

  def self.monthly_credit_slab_data(build_arr, id, hash_data)
    (1..12).each do |n|
      leave_credit = LeaveCreditSlab.find_by_employee_leave_type_id_and_leave_label(id, EmployeeLeaveType.month_name(n).downcase )
      build_arr["employee_leave_type_id"] = id
      build_arr["leave_label"] = EmployeeLeaveType.month_name(n).downcase
      build_arr["leave_count"] = hash_data["leave_count(#{EmployeeLeaveType.month_name(n).downcase})"].to_f
      build_arr["label_order"] = n
      EmployeeLeaveType.build_slab(build_arr, leave_credit) 
    end
    return true 
  end
  
  
  def self.quarter_credit_slab_data(build_arr, id, hash_data)
    (1..4).each do |n|
      leave_credit = LeaveCreditSlab.find_by_employee_leave_type_id_and_leave_label(id, EmployeeLeaveType.quarter_name(n).downcase )
      build_arr["employee_leave_type_id"] = id
      build_arr["leave_label"] = EmployeeLeaveType.quarter_name(n)
      build_arr["leave_count"] = hash_data["leave_count(#{EmployeeLeaveType.quarter_name(n).downcase})"].to_f
      build_arr["label_order"] = n
      EmployeeLeaveType.build_slab(build_arr, leave_credit)
    end
    return true
  end
  
  def self.half_yearly_credit_slab_data(build_arr, id, hash_data)
    (1..2).each do |n|
      leave_credit = LeaveCreditSlab.find_by_employee_leave_type_id_and_leave_label(id, EmployeeLeaveType.year_part(n).downcase )
      build_arr["employee_leave_type_id"] = id
      build_arr["leave_label"] = EmployeeLeaveType.year_part(n)
      build_arr["leave_count"] = hash_data["leave_count(#{EmployeeLeaveType.year_part(n).downcase})"].to_f    
      build_arr["label_order"] = n
      EmployeeLeaveType.build_slab(build_arr, leave_credit)
    end
    return true
  end
  
  def self.build_slab(build_arr, leave_credit)
    if leave_credit.present?
      leave_credit.update_attributes(:leave_count => build_arr["leave_count"])
    else
      credit_slab = LeaveCreditSlab.new(build_arr) 
      credit_slab.save
    end
    return true
  end
  
  def self.month_name(month)
    name = Date::MONTHNAMES[month]
    return name
  end
  
  def self.leave_count(leave_type, date = Date.today, leave_group = nil)
    credit_type = leave_type.credit_type
    credit_frequency = leave_type.credit_frequency
    if credit_type != "Slab" or credit_frequency == 1 or credit_frequency == 5
      leave = LeaveGroupLeaveType.find_by_leave_group_id_and_employee_leave_type_id(leave_group.id, leave_type.id)
      return leave.leave_count.to_f if leave.present? and leave.leave_count.present?
      type_leave = EmployeeLeaveType.find(leave_type.id)
      return type_leave.max_leave_count.to_f unless leave.present?  and leave.leave_count.present?
    else
      if credit_frequency == 2
        leave_label = EmployeeLeaveType.month_name(date.month).downcase
      elsif credit_frequency == 3
        querter = ((date.month - 1) / 3) + 1
        leave_label = EmployeeLeaveType.quarter_name(querter).downcase
      elsif credit_frequency == 4
        half = 1 if (1..6).include?(date.month)
        half = 2 if (7..12).include?(date.month)
        leave_label = EmployeeLeaveType.year_part(half).downcase
      end
      leave_count = LeaveGroupLeaveType.find_by_leave_group_id_and_employee_leave_type_id(leave_group.id, leave_type.id).try(:leave_count)
      credit_slab = LeaveCreditSlab.find_by_employee_leave_type_id_and_leave_label(leave_type.id, leave_label) unless leave_count.present?
      return credit_slab.leave_count.to_f unless leave_count.present?
      return leave_count.to_f if leave_count.present?
    end
  end
  
  def self.create_credit_record(type, date)
    leave_credit_record = LeaveAutoCreditRecord.find_by_leave_type_id(type.id)
    unless leave_credit_record.present?
    leave_credit_record = LeaveAutoCreditRecord.new(:leave_type_id => type.id, :date => date,  :action => "added") 
    return true if leave_credit_record.save
    else
     return true if leave_credit_record.update_attributes(:date => date)
    end
  end
  
  def self.update_credit_record(type, date)
    leave_credit_record = LeaveAutoCreditRecord.new(:leave_type_id => type.id, :date => date,  :action => "removed") 
    return true if leave_credit_record.save
  end
  
  def self.validate_leave_type
    error = []
    leave_types = EmployeeLeaveType.all
    leave_types.each do |leave_type|
      error << leave_type.id unless leave_type.credit_frequency.present? 
      error << leave_type.id if (leave_type.credit_frequency != 1 and leave_type.credit_frequency != 5 )  and leave_type.credit_type == " " 
    end
    return false if error.present?
    return true  unless error.present?
  end
  
  def self.leave_type_detials
    EmployeeLeaveType.active.collect(&:code)
  end
  
  LEAVE_STATUS = {1 => :creating_leave_type, 2 => :success, 3 => :leave_creation_failed }

  CARRY_FORWARD_TYPE = {1 => :any_count , 2=> :specific_count }
  
  CREDIT_FREQUENCIES = {1 => :days, 2 => :monthly, 3 => :quarterly, 4 => :half_yearly, 5 => :annually}
end
