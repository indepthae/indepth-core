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

class User < ActiveRecord::Base
  attr_accessor :password, :role, :old_password, :new_password, :confirm_password, :finance_flag

  validates_uniqueness_of :username,:case_sensitive => false #, :email
  validates_length_of     :username, :within => 1..20
  validates_length_of     :password, :within => 4..40, :allow_nil => true
  validates_format_of     :username, :with => /^[A-Z0-9]{1,}([\/_-]{1}[A-Z0-9]{1,})*$/i,
    :message => :must_contain_only_letters
  validates_format_of     :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,10}$/i,   :allow_blank=>true,
    :message => :must_be_a_valid_email_address
  validates_presence_of   :role , :on=>:create
  validates_presence_of   :password, :on => :create
  validates_presence_of   :first_name

  has_many :user_groups_users
  has_many :user_groups, :through => :user_groups_users
  has_and_belongs_to_many :privileges, :after_add => :clear_existing_cache, :after_remove => :clear_existing_cache do
    def find_target
      Configuration.cache_it(Configuration.fetch_model_cache_key(@reflection.klass,proxy_owner.id)) { super }
    end
  end

  def clear_existing_cache(privilege)
    Configuration.clear_model_cache("Privilege".constantize,self.id)
  end

  has_many  :user_events
  has_many  :events,:through=>:user_events

  has_many :user_menu_links
  has_many :menu_links, :through=>:user_menu_links
  has_many :remarks,:foreign_key=>'submitted_by'
  has_many :recieved_finance_transactions,:class_name=>"FinanceTransaction"
  has_many :advance_fee_collections

  has_one :student_entry,:class_name=>"Student",:foreign_key=>"user_id"
  has_one :guardian_entry,:class_name=>"Guardian",:foreign_key=>"user_id"
  has_one :archived_student_entry,:class_name=>"ArchivedStudent",:foreign_key=>"user_id"
  has_one :employee_entry,:class_name=>"Employee",:foreign_key=>"user_id"
  has_one :archived_employee_entry,:class_name=>"ArchivedEmployee",:foreign_key=>"user_id"
  has_one :biometric_information, :dependent => :destroy

  named_scope :active, :conditions => { :is_deleted => false }
  named_scope :inactive, :conditions => { :is_deleted => true }
  named_scope :username_equals, lambda{|username|{:conditions => ["username LIKE BINARY (?)",username]}}
  named_scope :name_or_username_like, lambda{|query| {:conditions =>
        ["ltrim(first_name) LIKE ? OR ltrim(last_name) LIKE ? OR username = ? OR
(concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(last_name))) LIKE ? ) ",
        "#{query}%", "#{query}%", "#{query}", "#{query}%"], :order => "first_name asc"}}

  
  after_save :create_default_menu_links
  before_destroy :remove_user_news_comments

  def before_save
    self.salt = random_string(8) if self.salt == nil
    self.hashed_password = Digest::SHA1.hexdigest(self.salt + self.password) unless self.password.nil?
    if self.new_record?
      self.admin, self.student, self.employee = false, false, false
      self.admin    = true if self.role == 'Admin'
      self.student  = true if self.role == 'Student'
      self.employee = true if self.role == 'Employee'
      self.parent = true if self.role == 'Parent'
      self.is_first_login = true
    end
  end

  def activate
    self.update_attribute('is_deleted',false)
  end

  def active?
    self.is_deleted==false
  end
  def create_default_menu_links
    changes_to_be_checked = ['admin','student','employee','parent']
    check_changes = self.changed & changes_to_be_checked
    if (self.new_record? or check_changes.present?)
      self.menu_links = []
      default_links = []
      if self.admin?
        main_links = MenuLink.find_all_by_name_and_higher_link_id(["human_resource","settings","students","calendar_text","news_text","event_creations"],nil)
        default_links = default_links + main_links
        main_links.each do|link|
          sub_links = MenuLink.find_all_by_higher_link_id(link.id)
          default_links = default_links + sub_links
        end
      elsif self.employee?
        own_links = MenuLink.find_all_by_user_type("employee")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      else
        own_links = MenuLink.find_all_by_name_and_user_type(["my_profile","timetable_text","academics","fees_text"],"student")
        default_links = own_links + MenuLink.find_all_by_name(["news_text","calendar_text"])
      end
      self.menu_links = default_links
    end
  end

  def sibling_enabled
    sibling_enabled = Configuration.get_config_value('EnableSibling')
    return true if (sibling_enabled.present? and sibling_enabled == "1")
    return false
  end

  def remove_user_news_comments
    comment_ids=NewsComment.all(:conditions=>["author_id=? AND is_approved=?",self.id,false]).collect(&:id)
    NewsComment.delete(comment_ids)
  end

  def student_record
    self.is_deleted ? self.archived_student_entry : self.student_entry
  end

  def employee_record
    self.is_deleted ? self.archived_employee_entry : self.employee_entry
  end

  def is_employee
    Authorization.current_user.employee_record.present? || Authorization.current_user.admin?
  end

  def manager
    current_user_id =  Authorization.current_user.id
    reportees = Employee.find_all_by_reporting_manager_id current_user_id
    reportees.present?
  end

  def student_document_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Student Documents")
    config.update_attributes(:feature_name=>"Student Documents ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end

  def hostel_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Hostel")
    config.update_attributes(:feature_name=>"Hostel ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end

  def gallery_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Gallery")
    config.update_attributes(:feature_name=>"Gallery ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end

  def transport_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Transport")
    config.update_attributes(:feature_name=>"Transport ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end

  def assignment_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Assignment")
    config.update_attributes(:feature_name=>"Assignment ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end

  def task_access?
    config = FeatureAccessSetting.find_or_create_by_feature_name("Tasks")
    config.update_attributes(:feature_name=>"Tasks ", :parent_can_access => false) if config.parent_can_access.nil?
    return config.parent_can_access
  end


  def in_reportees_list
    current_user_id =  Authorization.current_user.id
    reportees = Employee.find_all_by_reporting_manager_id current_user_id
    user_ids = reportees.collect{|e| e.user.id}
    user_ids.include?(self.id)
  end

  def pending_applications
    reportees = Employee.find_all_by_reporting_manager_id self.id
    total_leave_count = 0
    reportees.each do |e|
      app_leaves = e.apply_leaves.select{|leave| leave.viewed_by_manager == false}.count
      total_leave_count = total_leave_count + app_leaves
      return true if total_leave_count > 0
    end
  end

  def get_next_admission_no (current_no)
    ((current_no=~/\d+$/).nil? ? current_no.next : current_no.gsub(/\d+$/, current_no.scan(/\d+$/)[0].next))
  end

  def self.next_admission_no (user_type)
    last_user = User.last(:select=>"username",:conditions=>["#{user_type}=?",true])
    if last_user
      next_admission_no = last_user.get_next_admission_no(last_user.username)
      while User.exists?(:username=>next_admission_no) do
        next_admission_no = last_user.get_next_admission_no(next_admission_no)
      end
      return next_admission_no
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  def user_full_name
    if self.admin
      employee = Employee.find_by_user_id(id)
      return employee.full_name if employee.present?
      return  full_name unless employee.present?
    elsif self.student
      student = Student.find_by_user_id(id)
      return student.full_name
    elsif self.employee
      employee = Employee.find_by_user_id(id)
      return employee.full_name
    elsif self.parent
      guardian = Guardian.find_by_user_id(id)
      return guardian.full_name
    end  
  end
  
  def fetch_all_reminders
    Reminder.find(:all , :conditions => ["recipient = '#{self.id}' and is_deleted_by_recipient='#{false}'"], :order=>'created_at DESC')
  end

  def check_reminders
    reminders =[]
    reminders = Reminder.find(:all , :conditions => ["recipient = '#{self.id}'"])
    count = 0
    reminders.each do |r|
      unless r.is_read
        count += 1
      end
    end
    return count
  end

  def notifications
    Notification.all(:joins=>:notification_recipients, :conditions=>{:notification_recipients=>{:recipient_id=>id}},
      :order=>'created_at DESC')
  end

  def unread_notifications_count
    Notification.all(:joins=>:notification_recipients, :conditions=>{:notification_recipients=>{:recipient_id=>id, :is_read=>false}},
      :order=>'created_at DESC').count
  end

  def unread_notifications
    Notification.all(:joins=>:notification_recipients, :conditions=>{:notification_recipients=>{:recipient_id=>id, :is_read=>false}},
      :order=>'created_at DESC')
  end

  def unread_messages_count
    unread_messages.count
  end

  def unread_messages
    MessageThread.all(:select => "distinct message_threads.*",:conditions => ['message_threads.is_deleted = ?
            AND message_recipients.recipient_id = ? AND message_recipients.is_deleted = ? AND message_recipients.is_read = ?',false,id,false,false],
      :joins=>{:messages=>:message_recipients},
      :include=>:messages,
      :order=>'updated_at DESC', :limit=>8)
  end

  def can_message?
    MessageSetting.can_message?(self)
  end

  def self.authenticate?(username, password)
    u = User.active.first(:conditions => ["username LIKE BINARY(?)",username])
    u.hashed_password == Digest::SHA1.hexdigest(u.salt + password)
  end

  def random_string(len)
    randstr = ""
    chars = ("0".."9").to_a + ("a".."z").to_a + ("A".."Z").to_a
    len.times { randstr << chars[rand(chars.size - 1)] }
    randstr
  end

  def role_name
    return "#{t('admin')}" if self.admin?
    return "#{t('student_text')}" if self.student?
    return "#{t('employee_text')}" if self.employee?
    return "#{t('parent')}" if self.parent?
    return nil
  end

  def role_symbols
    prv = []
    privileges.map { |privilege| prv << privilege.name.underscore.to_sym } unless @privilge_symbols

    @privilge_symbols ||= if admin?
      [:admin] + prv
    elsif student?
      [:student] + prv
    elsif employee?
      [:employee] + prv
    elsif parent?
      [:parent] + prv
    else
      prv
    end
  end

  def is_allowed_to_mark_attendance?
    if self.employee?
      attendance_type = Configuration.get_config_value('StudentAttendanceType')
      if ((self.employee_record.subjects.present? and attendance_type == 'SubjectWise') or (self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present? and attendance_type == 'Daily'))
        return true
      end
    end
    return false
  end

  def can_view_results?
    if self.employee?
      return true if self.employee_record.batches.find(:all,:conditions=>{:is_deleted=>false,:is_active=>true}).present?
    end
    return false
  end

  def can_view_day_wise_report?
    attendance_type = Configuration.get_config_value('StudentAttendanceType')
    if self.admin? or (self.employee? and self.privileges.map{|p| p.name}.include?('StudentAttendanceView'))
      return (attendance_type == "Daily")
    else
      return (can_view_results? and attendance_type == "Daily")
    end
  end

  def has_assigned_subjects?(batch_id = nil)
    if self.employee?
      employee_subjects= batch_id.nil? ? self.employee_record.subjects : self.employee_record.subjects.all(:conditions=>{:batch_id=>batch_id})
      if employee_subjects.empty?
        return false
      else
        return true
      end
    else
      return false
    end
  end

  def roll_number_enabled?
    return Configuration.find_or_create_by_config_key('EnableRollNumber').config_value == "1" ? true : false
  end
  # TODO replace this method name with some meaningfull name
  def has_required_control?
    if has_assigned_subjects?
      return true
    else
      if can_view_results?
        return true
      else
        return false
      end
    end
  end

  def has_required_controls?
    @config=Configuration.find_by_config_key('StudentAttendanceType')
    if @config.config_value == "Daily"
      return can_view_results?
    else
      return true if has_assigned_subjects?
      return true if can_view_results?
      return false
    end
  end

  def has_exam_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "ExaminationControl" or self.privileges.map(&:name).include? "EnterResults" or self.privileges.map(&:name).include? "ViewResults"
  end

  def has_required_exam_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "ExaminationControl" or self.privileges.map(&:name).include? "EnterResults"
  end

  def has_required_custom_remarks_privileges?
    return true if self.admin? or self.privileges.map(&:name).include? "StudentsControl"
  end

  def has_required_batches?
    if cce_enabled?
      if !self.parent? and !self.student? and self.employee_record.batches.present?
        self.employee_record.batches.each do |batch|
          return true if batch.course.grading_type=="3" and batch.course.is_deleted==false and batch.is_active == true
        end
        return false
      elsif self.student?
        return true if self.student_record.batch.course.grading_type=="3" and self.student_record.batch.course.is_deleted==false
      elsif self.parent?
        return true if self.parent_record.batch.course.grading_type=="3" and self.parent_record.batch.course.is_deleted==false
      else
        return false
      end
    else
      return false
    end
  end

  def has_required_subjects?
    if cce_enabled?
      if self.employee_record.subjects.present?
        self.employee_record.subjects.each do |subject|
          return true if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
        end
        return false
      else
        return false
      end
    else
      return false
    end
  end

  def has_cce_subjects?
    if has_assigned_subjects?
      self.employee_record.subjects.each do |subject|
        return true if subject.batch.course.grading_type=="3" and subject.batch.course.is_deleted==false
      end
      return false
    else
      if can_view_results?
        self.employee_record.batches.each do |batch|
          return true if batch.course.grading_type=="3" and batch.course.is_deleted==false
        end
        return false
      end
    end
    return false
  end

  def icse_enabled?
    @icse_enabled ||= Configuration.icse_enabled?
  end

  def cce_enabled?
    @icse_enabled ||= Configuration.cce_enabled?
  end

  def gpa_enabled?
    Configuration.has_gpa?
  end

  def clear_menu_cache
    Rails.cache.delete("user_autocomplete_menu#{self.id}")
    Configuration.clear_model_cache("Privilege".constantize, self.id)
    clear_user_menu_quick_link_cache
    menu_categories = MenuLinkCategory.all
    menu_categories.each do|category|
      clear_user_menu_category_link_cache(category)
    end
  end

  def clear_user_menu_quick_link_cache
    Rails.cache.delete(menu_link_cache_key)
    ActionController::Base.new.expire_fragment(menu_link_cache_key)
  end

  def clear_user_menu_category_link_cache (category)
      ActionController::Base.new.expire_fragment(menu_link_cache_key(category.id))
      Rails.cache.delete(menu_link_cache_key(category.id))
  end

  def menu_link_cache_key (category_id=nil)
    cache_key = if parent?
      ward_id = guardian_entry.present? ? guardian_entry.current_ward_id : 0
      category_id.nil? ? "user-menu-links-user-#{self.id}-#{ward_id}" : "user-menu-links-#{category_id}-user-#{self.id}-#{ward_id}"
    else
      category_id.nil? ? "user-menu-links-user-#{self.id}" : "user-menu-links-#{category_id}-user-#{self.id}"
    end
    plugins_hash_key = MultiSchool.current_school.available_plugin.try(:updated_at).to_i
    "#{cache_key}-#{plugins_hash_key}"
  end

  def clear_school_name_cache(request_host)
    Rails.cache.delete("current_school_name/#{request_host}")
  end

  def parent_record
    #    p=Student.find_by_admission_no(self.username[1..self.username.length])
    unless guardian_entry.nil?
      guardian_entry.current_ward
    else
      Student.find_by_admission_no(self.username[1..self.username.length])
    end

    #    p '-------------'
    #    p self.username[1..self.username.length]
    #     Student.find_by_sibling_no_and_immediate_contact(self.username[1..self.username.length])
    #guardian_entry.ward
  end

  def has_subject_in_batch(b)
    employee_record.subjects.collect(&:batch_id).include? b.id
  end

  def has_subject_privilege(sub_id)
    sub_ids = employee_record.subject_ids
    employee_record.batches.each{|e| sub_ids.concat(e.subject_ids)}
    return sub_ids.include? sub_id
  end

  def has_common_remark_privilege(batch_id)
    has_required_exam_privileges? or employee_record.batch_ids.include? batch_id
  end

  def days_events(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? between date(events.start_date) and date(events.end_date)",date])
    when "Student"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Parent"
      all_events+= events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    when "Employee"
      all_events+= events.all(:conditions=>["? between events.start_date and events.end_date",date])
      all_events+= employee_record.employee_department.events.all(:conditions=>["? between date(events.start_date) and date(events.end_date)",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_exam = true",date])
      all_events+= Event.all(:conditions=>["(? between date(events.start_date) and date(events.end_date)) and is_common = true",date])
    end
    all_events
  end

  def next_event(date)
    all_events=[]
    case(role_name)
    when "Admin"
      all_events=Event.find(:all,:conditions => ["? < date(events.end_date)",date],:order=>"start_date")
    when "Student"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= student_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Parent"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.user.events.all(:conditions=>["? < date(events.end_date)",date])
      all_events+= parent_record.batch.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    when "Employee"
      all_events+= events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= employee_record.employee_department.events.all(:conditions=>["? < date(events.end_date)",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_exam = true",date],:order=>"start_date")
      all_events+= Event.all(:conditions=>["(? < date(events.end_date)) and is_common = true",date],:order=>"start_date")
    end
    start_date=all_events.collect(&:start_date).min
    unless start_date
      return ""
    else
      next_date=(start_date.to_date<=date ? date+1.days : start_date )
      next_date
    end
  end
  def soft_delete
    self.update_attributes(:is_deleted =>true)
    UserGroupsUser.destroy_all(["user_id=?",self.id])
  end

  def user_type
    admin? ? "Admin" : employee? ? "Employee" : student? ? "Student" : "Parent"
  end
  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end
  def school_name
    Configuration.get_config_value('InstitutionName')
  end

  def is_a_batch_tutor?
    employee = self.employee_entry
    employee.is_a_batch_tutor?
  end

  def  is_a_tutor_for_this_batch(batch)
    employee = self.employee_entry
    unless employee.nil?
      employee.is_a_tutor_for_this_batch(batch)
    else
      return false
    end
  end

  def is_tutor_and_in_student_batch
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    if employee.is_a_batch_tutor?
      user_ids = self.student_record.batch_in_context.employees.collect{|e| e.user.id}
      return user_ids.include?(current_user.id)
    else
      return false
    end
  end

  def is_batch_tutor_or_subject_teacher_in_cce_course
    current_user=Authorization.current_user
    employee = current_user.employee_entry
    return true if employee.batches.all(:joins=>:course,:conditions=>{:courses=>{:grading_type=>"3"}}).present?
    return true if employee.subjects.all(:joins=>{:batch=>:course},:conditions=>{:courses=>{:grading_type=>"3"}}).present?
    return false
  end

  def in_batches_list
    user_ids = []
    Course.find(self.id).batches.each do |batch|
      user_ids += batch.employees.collect{|e| e.user.id}
    end
    user_ids.include?(Authorization.current_user)
  end

  def is_a_batch_tutor
    is_a_batch_tutor?
  end

  def is_a_subject_teacher(batch_id = nil)
    has_assigned_subjects?(batch_id = nil)
  end


  def teaching_batches
    employee = self.employee_entry
    employee.batches
  end
  def teaching_courses
    teaching_batches.collect(&:course).uniq
  end

  def approve_reject_privilege
    unless admin?
      unless self.finance_flag
        return (self.privileges.map(&:name).include? "PayrollAndPayslip" or self.privileges.map(&:name).include? "EmployeeReports")
      else
        return self.privileges.map(&:name).include? "ApproveRejectPayslip"
      end
    end
    return true
  end

  def payroll_privilege
    unless admin?
      if self.privileges.map(&:name).include? "PayrollAndPayslip" or self.privileges.map(&:name).include? "EmployeeReports"
        return true
      else
        return false
      end
    else
      return true
    end
  end

  def search_privilege
    unless admin?
      if self.privileges.map(&:name).include? "EmployeeSearch" or self.privileges.map(&:name).include? "EmployeeReports"
        return true
      else
        return false
      end
    else
      return true
    end
  end
  def subject_association_privilege
    unless admin?
      if self.privileges.map(&:name).include? "EmployeeReports"
        return true
      else
        return false
      end
    else
      return true
    end
  end

  class << self

    def fetch_filter_criteria(user_type = 'students')
      case user_type
      when 'students', 'parents'
        Batch.active.group_by(&:course_id).map{|course, batches| [batches.first.course.course_name, batches.map{|b| [b.full_name, b.id]}]}
      when 'employees'
        EmployeeDepartment.active.map{|ed| [ed.name, ed.id]}
      end
    end

    def fetch_users(user_type, query, filter, type,forced_type)
      flag = false
      status = false
      if forced_type == "all"
        flag = false
      else
        flag = true
        status = true if forced_type == "blocked"
        status = false if forced_type == "unblocked"


      end
      if(type == 'query' and query.length >= 0)
        if flag
          active.name_or_username_like(query).all(:conditions=>{:is_blocked=>status}) if query.present?
        else
          active.name_or_username_like(query) if query.present?
        end
      else
        case user_type
        when 'students'
          if filter.present?
            students = Student.find_all_by_batch_id(filter, :conditions => { :is_active => true },:order =>'first_name ASC', :include => :user)
            if flag
              students.collect { |student| student.user if student.user.is_blocked == status}.compact
            else
              students.collect { |student| student.user }.compact
            end
          end
        when 'parents'
          if filter.present?
            user_ids = Guardian.find(:all, :select=>'guardians.user_id',:joins=>'INNER JOIN students ON students.immediate_contact_id = guardians.id',
              :conditions => 'students.batch_id = ' + filter + ' AND is_active=1').collect(&:user_id).compact
            if flag
              find_all_by_id(user_ids,:conditions=>["is_deleted is false AND is_blocked = ?",status],:order =>'first_name ASC')
            else
              find_all_by_id(user_ids,:conditions=>"is_deleted is false",:order =>'first_name ASC')
            end
          end
        when 'employees'
          if filter.present?
            employees = Employee.find_all_by_employee_department_id(filter, :order =>'first_name ASC', :include => :user)
            if flag
              employees.collect { |employee| employee.user if employee.user.is_blocked == status}.compact
            else
              employees.collect { |employee| employee.user}.compact unless flag
            end
          end
        when 'admins'
          if flag
            active.find(:all, :conditions => {:admin => true,:is_blocked => status}, :order => 'first_name ASC')
          else
            active.find(:all, :conditions => {:admin => true}, :order => 'first_name ASC')
          end
        end
      end
    end
    
    def fetch_user_record(id, type=nil)
      if type == "student" || type == "parent" 
        return Student.find_by_user_id(id)
      elsif type == "employee"
        return Employee.find_by_user_id(id)
      end  
            
    end  

  end
end
