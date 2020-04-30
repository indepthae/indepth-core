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
class Student < ActiveRecord::Base
  extend FeeDefaultersSqlGenerator
  attr_accessor_with_default(:biometric_id) { BiometricInformation.find_by_user_id(user_id).try(:biometric_id) }

  include CceReportMod
  include CsvExportMod
  VALID_BLOOD_GROUPS = ["A+", "A-", "A1+", "A1-", "A1B+", "A1B-", "A2-", "A2+", "A2B+", "A2B-", "B+", "B-", "B1+", "O+", "O-", "AB+", "AB-"]
  validates_uniqueness_of :roll_number, :scope => "batch_id", :message => "already taken", :allow_blank => true
  validates_format_of :roll_number, :with => /^[A-Z0-9_-]*$/i, :message => :must_contain_only_letters, :allow_blank => true
  validates_length_of :roll_number, :maximum => 15, :allow_blank => true
  belongs_to :country
  belongs_to :batch
  belongs_to :student_category
  belongs_to :nationality, :class_name => 'Country'
  belongs_to :user

  before_validation :update_roll_number
  before_validation :update_country_and_nationality

  #  has_one    :immediate_contact,:class_name => 'Guardian',:foreign_key => 'id',:primary_key => 'immediate_contact_id'
  belongs_to :immediate_contact, :class_name => 'Guardian'
  has_one :student_previous_data
  has_many :student_previous_subject_mark
  has_many :student_attachments
  has_many :student_attachment_records
  #  has_many   :guardians, :foreign_key => 'ward_id'
  has_many :guardians, :foreign_key => 'ward_id', :primary_key => :sibling_id
  has_many :finance_transactions, :as => :payee
  has_many :multi_fee_discounts, :as => :receiver
  has_many :cancelled_finance_transactions, :foreign_key => :payee_id, :conditions => ['payee_type = ?', 'Student']
  has_many :attendances
  has_many :finance_fees
  has_many :fee_category, :class_name => "FinanceFeeCategory"
  has_many :students_subjects
  has_many :subjects, :through => :students_subjects
  has_many :student_additional_details
  has_many :batch_students
  has_many :student_records
  has_many :record_addl_attachments, :through => :student_records
  has_many :subject_leaves
  has_many :grouped_exam_reports
  has_many :cce_reports
  has_many :asl_scores
  has_many :upscale_scores
  has_many :assessment_scores
  has_many :exam_scores
  has_many :previous_exam_scores
  has_many :icse_reports
  has_many :multi_fees_transactions
  has_many :multi_transaction_fines, :as => :receiver
  has_many :finance_transaction_ledgers, :as => :payee
  has_many :remarks
  has_many :student_discounts, :class_name => 'FeeDiscount', :foreign_key => 'receiver_id', :conditions => "receiver_type='Student'"
  has_many :student_particulars, :class_name => 'FinanceFeeParticular', :foreign_key => 'receiver_id', :conditions => "receiver_type='Student'"
  has_many :previous_batches, :source => :batch, :through => :batch_students
  accepts_nested_attributes_for :remarks
  accepts_nested_attributes_for :student_records, :allow_destroy => true
  #has_many   :siblings,:class_name=>'Student',:primary_key=>:sibling_id
  has_many :student_coscholastic_remarks
  has_many :student_coscholastic_remark_copies
  has_many :converted_assessment_marks
  has_many :individual_reports
  has_many :assessment_marks
  has_many :gradebook_attendances
  has_many :gradebook_remarks
  has_one :father, :class_name => 'Guardian', :foreign_key => 'ward_id', :primary_key => :sibling_id, :conditions=>['guardians.relation = ?', 'father']
  has_one :mother, :class_name => 'Guardian', :foreign_key => 'ward_id', :primary_key => :sibling_id, :conditions=>['guardians.relation = ?', 'mother']  
  
  has_many :generated_certificates, :as => :issued_for
  has_many :generated_id_cards, :as => :issued_for
  has_many :master_particular_reports
  has_many :user_groups_users, :as  => :member

  named_scope :admission_no_equals, lambda { |adm_no| {:conditions => ["students.admission_no LIKE BINARY(?)", adm_no]} }
  named_scope :country_name_equals, lambda { |name| {:joins => [:country, :nationality], :conditions => ["countries.name = ?", name]} }
  named_scope :nationality_name_equals, lambda { |name| {:joins => [:country, :nationality], :conditions => ["nationalities_students.name = ?", name]} }
  named_scope :name_or_admssn_no_as, lambda { |query| {:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR admission_no LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]} }
  named_scope :student_name_as, lambda { |query| {:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? OR concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ?", "#{query}%", "#{query}%", "#{query}%", "#{query}%", "#{query}%"]} }
  named_scope :active, :conditions => {:is_active => true}
  named_scope :with_full_name_only, :select => "id, CONCAT_WS('',first_name,' ',last_name) AS name,first_name,last_name", :order => :first_name
  named_scope :with_name_admission_no_only, :select => "id, CONCAT_WS('',first_name,' ',last_name,' - ',admission_no) AS name,first_name,last_name,admission_no", :order => :first_name
  named_scope :with_full_name_admission_no, :select => "id, CONCAT_WS('',first_name,' ', middle_name, ' ',last_name,' (',admission_no,')&#x200E;') AS name,first_name,middle_name,last_name,admission_no,admission_date", :order => :first_name
  named_scope :with_full_name_roll_number, :select => "id, CONCAT_WS('',first_name,' ', middle_name, ' ',last_name,' (',roll_number,')&#x200E;') AS name,first_name,middle_name, last_name,roll_number,admission_date", :order => :first_name
  named_scope :with_full_name_roll_number_and_batch, :select => "id, CONCAT_WS('',first_name,' ', middle_name, ' ', last_name,' ',batch_id,' (',roll_number,')&#x200E;') AS name,first_name, middle_name, last_name,batch_id,roll_number,admission_date", :order => :first_name
  named_scope :with_full_name_admission_no_and_batch, :select => "id, CONCAT_WS('',first_name,' ', middle_name, ' ', last_name,' ',batch_id,' (',admission_no,')&#x200E;') AS name,first_name, middle_name, last_name,batch_id,admission_no,admission_date", :order => :first_name
  named_scope :previous_records, :select => "students.*,batch_students.roll_number roll_number_in_context_id,if(asl_scores.speaking,asl_scores.speaking,'-') speaking,if(asl_scores.listening,asl_scores.listening,'-') listening,subjects.asl_mark", :joins => "INNER JOIN batch_students on batch_students.student_id = students.id LEFT OUTER JOIN asl_scores on asl_scores.student_id = batch_students.student_id and asl_scores.exam_id=1843  LEFT OUTER JOIN `exams` ON `exams`.id = `asl_scores`.exam_id LEFT OUTER JOIN `subjects` ON `subjects`.id = `exams`.subject_id AND subjects.`is_deleted` = 0", :order => "students.first_name ASC"
  named_scope :by_first_name, :order => 'first_name', :conditions => {:is_active => true}, :include => [:father, :mother]
  named_scope :by_full_name, :order => 'first_name,middle_name, last_name', :conditions => {:is_active => true}
  named_scope :by_roll_number, :order => 'roll_number', :conditions => {:is_active => true}
  named_scope :student_with_siblings, lambda {|sort_order|
    { :order=>sort_order, 
      :select=> "students.*,group_concat(c1.code) as sibling_course_name, group_concat(s2.first_name) as sibling_fname,group_concat(s2.middle_name) as sibling_mname, group_concat(s2.last_name) as sibling_lname, group_concat(s2.admission_no) sibling_admission_nos, group_concat(s2.id) sibling_ids ,group_concat(b1.name) as batch_name, b2.name as student_batch", 
      :joins => "inner join students s2 on students.sibling_id = s2.sibling_id and students.id <> s2.id inner join batches b1 on s2.batch_id=b1.id inner join batches b2 on students.batch_id=b2.id inner join courses c1 on b1.course_id=c1.id",
      :include => "guardians",
      :group => "students.id"}
  }
  named_scope :primary_student_with_siblings, lambda {|sort_order|
    { :order=>sort_order, 
      :select=> "students.*,group_concat(c1.code) as sibling_course_name, group_concat(s2.first_name) as sibling_fname, group_concat(s2.middle_name) as sibling_mname, group_concat(s2.last_name) as sibling_lname, group_concat(s2.admission_no) sibling_admission_nos, group_concat(s2.id) sibling_ids ,group_concat(b1.name) as batch_name, b2.name as student_batch", 
      :joins => "inner join students s2 on students.sibling_id = s2.sibling_id and students.id <> s2.id inner join batches b1 on s2.batch_id=b1.id inner join batches b2 on students.batch_id=b2.id inner join courses c1 on b1.course_id=c1.id",
      :include => "guardians",
      :group => "students.id"}
  }
  named_scope :with_batch, lambda { |batch_id|
    {:conditions => {:batch_id => batch_id}}
  }
  named_scope :fee_defaulters, lambda {{:select => '*,sum(balance) balance', :joins => "INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id", :group => 'students.id', :include => {:batch => :course}}}
  named_scope :fee_defaulters_balance, lambda { |student_ids| {:select => "*,COALESCE(SUM(balance),0) balance, batches.name , courses.course_name, CONCAT(courses.code,'-',batches.name) as batch_full_name ", :joins => "LEFT OUTER JOIN #{derived_sql_table} finance on finance.student_id=students.id LEFT OUTER JOIN batches on batches.id = students.batch_id LEFT OUTER JOIN courses on courses.id = batches.course_id", :conditions=> ['students.id in (?)',student_ids],:group => 'students.id',:include => {:batch => :course}}}
  named_scope :fee_defaulters_info, lambda { |student_ids| {:select => 'students.id,students.immediate_contact_id,students.phone2,students.first_name,students.middle_name,students.last_name,students.batch_id,students.is_sms_enabled,sum(balance) balance', :joins => "INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id", :conditions=> ['students.id in (?)',student_ids], :group => 'students.id'}}
  
  delegate :first_name,:last_name,:relation,:translated_relation,:username,
    :dob,:education,:occupation,
    :income,:email,:office_address_line1,
    :office_address_line2,:city,:state,
    :office_phone1,:mobile_phone,
    :to=>:immediate_contact,:prefix=>"parent",:allow_nil=>true
  delegate :first_name,:last_name,:relation,:translated_relation,:username,
    :dob,:education,:occupation,
    :income,:email,:office_address_line1,
    :office_address_line2,:city,:state,
    :office_phone1,:mobile_phone,
    :to=>:immediate_contact,:prefix=>"immediate_contact",:allow_nil=>true
  delegate :first_name,:last_name,:username,:dob,:education,:occupation,
    :income,:email,:office_address_line1,
    :office_address_line2,:city,:state,
    :office_phone1,:mobile_phone,
    :to=>:father,:prefix=>"father",:allow_nil=>true
  delegate :first_name,:last_name,:username,:dob,:education,:occupation,
    :income,:email,:office_address_line1,
    :office_address_line2,:city,:state,
    :office_phone1,:mobile_phone,
    :to=>:mother,:prefix=>"mother",:allow_nil=>true
       
  validates_presence_of :admission_no, :admission_date, :first_name, :batch_id, :date_of_birth, :nationality_id
  validates_uniqueness_of :admission_no, :case_sensitive => false
  validates_presence_of :gender
  validates_format_of :email, :with => /^[A-Z0-9._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,10}$/i, :allow_blank => true,
    :message => :must_be_a_valid_email_address
  validates_format_of :admission_no, :with => /^[\/A-Z0-9_-]*$/i,
    :message => :must_contain_only_letters

  #  validates_associated :user
  after_validation :create_user_and_validate

  before_save :is_active_true

  before_save :save_biometric_info

  after_create :set_sibling, :verify_and_send_sms, :send_notification
  
  after_update :verify_update_and_send_sms
  after_update :delete_nil_student_records

  before_destroy :handle_student_additional_data
  before_destroy :handle_student_records_data
  before_destroy :update_cancelled_finance_transactions_details

  before_update :batch_update, :if => Proc.new { |s| s.batch_id_changed? }
  validate :student_records_data
  validate :is_batch_transfer?, :if => Proc.new { |s| s.batch_id_changed? && !s.new_record? }
  validate :is_in_active_batch?, :if => Proc.new { |s| s.batch_id.present? }

  attr_writer :is_batch_transfer
  attr_accessor :archived 
  
  VALID_IMAGE_TYPES = ['image/gif', 'image/png', 'image/jpeg', 'image/jpg']

  has_attached_file :photo,
    :styles => {:original => "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types => VALID_IMAGE_TYPES

  validates_attachment_content_type :photo, :content_type => VALID_IMAGE_TYPES,
    :message => 'Image can only be GIF, PNG, JPG', :if => Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000, \
    :message => 'must be less than 500 KB.', :if => Proc.new { |p| p.photo_file_name_changed? }
  
  #when archived student is casted to student   
  has_many :archived_guardians, :foreign_key => 'ward_id', :primary_key => :sibling_id

  # advance fee payments
  has_many :advance_fee_collections
  has_one :advance_fee_wallet
  has_many :advance_fee_deductions

  def effective_guardians
    self.attributes["current_type"].present? && current_type == 'archived' ? archived_guardians : guardians  
  end
  
  
  def ef_father
    effective_guardians.to_a.find{|x| x.relation.downcase == "father"}
  end
  
  def update_country_and_nationality
    self.nationality_id = Configuration.default_country unless nationality_id.present?
    self.country_id = Configuration.default_country unless country_id.present?
  end  
  
  def ef_mother
    effective_guardians.to_a.find{|x| x.relation.downcase == "mother" }
  end
  
  
  def ef_immediate_contact
    effective_guardians.to_a.find{|x| (x.class.name=="ArchivedGuardian" ? x.former_id : x.id)  == self.immediate_contact_id}
  end
  
  
  def self.decide_and_find(id)
    find_by_id(id) || ArchivedStudent.find_by_former_id(id)
  end
  
  def joining_course
    if self.batch_students.present?
      return self.batch_students.first.batch.course.full_name
    else 
      return self.batch.course.full_name
    end
  end

  def verify_and_send_sms
    unless self.archived
      AutomatedMessageInitiator.student_admission(self)  
      verify_update_and_send_sms if self.changed and self.changed.include? 'immediate_contact_id'
    end
  end
  
  def verify_update_and_send_sms
    unless self.archived
      AutomatedMessageInitiator.student_immediate_contact_changed(self)   if self.changed and self.changed.include? 'immediate_contact_id'
    end
  end
  
  def s_id
    id
  end
  
  def send_notification
    if batch.course.enable_student_elective_selection
      unless batch.elective_groups.active.empty?
        batch.elective_groups.active.each do |eg|
          if !eg.end_date.nil? && !eg.subjects.active.empty? && eg.end_date >= Date.today
            end_date = eg.end_date
            recipients_array = [user_id]
            content = "Electives for group #{eg.name} are available.Please select it on or before #{end_date}"
            links = {:target=>'choose_elective',:target_param=>'student_id'}
            inform(recipients_array,content,'Subject',links)
          end
        end
      end
    end
  end
  
  def fetch_school_report(grb_id)
    IndividualReport.find(:all,:conditions=>["generated_report_batch_id = ? and student_id = ?", grb_id, self.id]).first
  end
  
  def get_reports(batch_id,type)
    list = []
    arr = []
    case type
    when 'exam_report' 
      assessment_term = AssessmentTerm.all
      reports = individual_reports.all(:joins => [:generated_report_batch,:assessment_group], :select => 'individual_reports.reportable_id, individual_reports.reportable_type,assessment_groups.name,assessment_groups.parent_id',
        :order=>"parent_id",:conditions => ["generated_report_batches.batch_id = ? AND reportable_type = 'AssessmentGroup'", batch_id], :include => :reportable).group_by(&:parent_id)
      reports.each_pair do |key, value|
        arr = [assessment_term.find{|obj| obj.id == key.to_i}.name,value.map{|v| [v.name,v.reportable_id]}]
        list.push(arr)
      end
      reports = list
    when 'term_report'
      reports = individual_reports.all(:joins => [:generated_report_batch,:assessment_term], :select => 'individual_reports.*, generated_report_batches.batch_id,assessment_terms.name',
        :conditions => ["generated_report_batches.batch_id = ? AND reportable_type = 'AssessmentTerm'", batch_id], :include => :reportable)
    when 'plan_report'
      reports = individual_reports.all(:joins => [:generated_report_batch,:assessment_plan], :select => 'individual_reports.*, generated_report_batches.batch_id,assessment_plans.name',
        :conditions => ["generated_report_batches.batch_id = ? AND reportable_type = 'AssessmentPlan'", batch_id], :include => :reportable)
    else
      reports = []
    end
    reports
  end
  
  def fetch_individual_reports(batch_id)
    individual_reports.all(:joins => :generated_report_batch, :select => 'individual_reports.*,generated_report_batches.batch_id',
      :conditions => ["generated_report_batches.batch_id IN (?) AND generated_report_batches.report_published = true", [batch_id]+ self.graduated_batches.collect(&:id)], :include => :reportable).group_by(&:batch_id)
  end
  
  def name_with_suffix
    value = Fedena.sort_order_config
    if value == "admission_no"
      return "#{self.full_name} (#{self.admission_no})&#x200E;" 
    elsif value == "roll_number" 
      if self.roll_number.present? 
        return "#{self.full_name} (#{self.roll_number})&#x200E;" 
      else
        return "#{self.full_name} (-)&#x200E;"
      end
    else
      if Configuration.enabled_roll_number?
        return "#{self.full_name} (#{self.roll_number})&#x200E;" if self.roll_number.present?
        return "#{self.full_name} (-)&#x200E;" unless self.roll_number.present?
      else
        return "#{self.full_name} (#{self.admission_no})&#x200E;"
      end
    end
  end
  
  def current_subjects
    subjects.all(:conditions=>{:batch_id=>batch_id})
  end

  def self.sort_order 
    Configuration.get_sort_order
  end

  def self.check_and_sort
    if roll_number_config_value == "1"
      return "soundex(roll_number),length(roll_number),roll_number ASC"
    else
      return "first_name ASC"
    end
  end
  
  def self.get_hash_priority
    hash = {:student_additional_details=>[:name,:value]}
    return hash
  end
  
  def self.roll_number_config_value
    Configuration.find_by_config_key('EnableRollNumber').config_value
  end
  
  def full_course_name
    "#{self.batch_in_context.course.course_name} - #{self.batch_in_context.name}"
  end
  
  def full_batch_course_name
    "#{self.batch_in_context.course.course_name} - #{self.batch_in_context.name}"
  end

  def in_format_dob
    format_date(date_of_birth, :format => :short)
  end

  def roll_number_in_context
    config = Configuration.find_by_config_key("EnableRollNumber")
    if config.present? and config.config_value == "1"
      if attributes.include? "roll_number_in_context_id"
        return roll_number_in_context_id.present? ? roll_number_in_context_id : "-"
      end
      if batch_id == batch_in_context_id
        roll_number.present? ? roll_number : "-"
      else
        prev_data = BatchStudent.last(:conditions => {:batch_id => batch_in_context_id, :student_id => id})
        prev_data.roll_number.present? ? prev_data.roll_number : "-"
      end
    end
  end

  def delete_student_cce_report_cache
    self.batch_id=batch_in_context_id
    self.delete_individual_cce_report_cache
  end

  def generate_cce_student_wise_reports
    CceReport.transaction do
      delete_student_cce_report_setting_copy
      create_student_cce_report_setting_copy
      delete_student_upscaled_values
      delete_student_scholastic_reports
      create_student_scholastic_reports
      delete_student_coscholastic_reports
      create_student_coscholastic_reports
      delete_student_wise_coscholastic_remarks_copy
      create_student_wise_coscholastic_remarks_copy
      update_student_asl_scores
    end
  end

  def delete_student_wise_coscholastic_remarks_copy
    student_coscholastic_remark_copies.all(:conditions => {:batch_id => batch_in_context_id}).each do |e|
      e.destroy
    end
  end

  def create_student_wise_coscholastic_remarks_copy
    orm = CceReportSetting.get_setting_value('ObservationRemarkMode')
    if orm == "0"
      sscr = student_coscholastic_remarks.all(:conditions => {:batch_id => batch_in_context_id})
      if sscr.present?
        sscr.each do |entry|
          StudentCoscholasticRemarkCopy.create(:student_id => entry.student_id, :batch_id => entry.batch_id, :observation_id => entry.observation_id, :remark => entry.remark)
        end
      end
    else
      ob_ids = cce_reports.coscholastic.collect(&:observable_id).uniq
      if ob_ids.present?
        Observation.find_all_by_id(ob_ids).each do |observation|
          limit=observation.observation_group.di_count_in_report
          dis=DescriptiveIndicator.co_scholastic.all(:joins => ["INNER JOIN assessment_scores ass on ass.descriptive_indicator_id=descriptive_indicators.id"], :conditions => ["ass.batch_id =? and ass.student_id=? and descriptive_indicators.describable_id=?", batch_in_context_id, id, observation.id], :order => "ass.grade_points DESC,descriptive_indicators.sort_order ASC", :limit => limit)
          remark = dis.collect(&:name).join(', ')
          StudentCoscholasticRemarkCopy.create(:student_id => id, :batch_id => batch_in_context_id, :observation_id => observation.id, :remark => remark)
        end
      end
    end
  end

  def delete_student_cce_report_setting_copy
    CceReportSettingCopy.delete_all(["student_id = ? and batch_id=?", id, batch_in_context_id])
  end

  def generate_general_settings_copy
    general_settings = ["ReportHeader", "Attendance", "AffiliationNo", "NormalReportHeader", "HeaderSpace", "StudentDetail1", "StudentDetail2", "StudentDetail3", "StudentDetail4", "StudentDetail5", "StudentDetail6", "StudentDetail7", "StudentDetail8", "GradingLevel", "GradingLevelPosition", "Signature", "SignLeftText", "SignCenterText", "SignRightText", "LastPage"]
    general_settings.each do |gs|
      setting=CceReportSetting.find_by_setting_key(gs)
      unless setting
        setting_value = CceReportSetting::FALLBACK_SETTINGS[gs]
      else
        setting_value = setting.setting_value
      end
      CceReportSettingCopy.create(:student_id => '', :batch_id => batch_in_context_id, :setting_key => gs, :data => setting_value)
    end
  end

  def generate_health_status_settings_copy
    other_settings_1 = ["Height", "Weight", "BloodGroup", "VisionLeft", "VisionRight", "DentalHygiene"]
    hs=CceReportSetting.find_by_setting_key('HealthStatus')
    unless hs
      hs_setting_value = CceReportSetting::FALLBACK_SETTINGS['HealthStatus']
    else
      hs_setting_value = hs.setting_value
    end
    other_settings_1.each do |os|
      setting=CceReportSetting.find_by_setting_key(os)
      unless setting
        setting_value = CceReportSetting::FALLBACK_SETTINGS[os]
      else
        setting_value = setting.setting_value
      end
      if hs_setting_value != "" and setting_value != "" and RecordGroup.find_by_id(hs_setting_value).present? and RecordGroup.find_by_id(hs_setting_value).records.collect(&:id).include?(setting_value.to_i)
        data=StudentRecord.first(:conditions => {:student_id => id, :batch_id => batch_in_context_id, :additional_field_id => setting_value})
        CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => os, :data => data.present? ? data.additional_info : '')
      else
        CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => os, :data => '')
      end
    end
  end

  def generate_self_awareness_settings_copy
    other_settings_2 = ["MyGoals", "MyStrengths", "InterestHobbies", "Responsibility"]
    sa=CceReportSetting.find_by_setting_key('SelfAwareness')
    unless sa
      sa_setting_value = CceReportSetting::FALLBACK_SETTINGS['SelfAwareness']
    else
      sa_setting_value = sa.setting_value
    end
    other_settings_2.each do |os|
      setting=CceReportSetting.find_by_setting_key(os)
      unless setting
        setting_value = CceReportSetting::FALLBACK_SETTINGS[os]
      else
        setting_value = setting.setting_value
      end
      if sa_setting_value != "" and setting_value != "" and RecordGroup.find_by_id(sa_setting_value).present? and RecordGroup.find_by_id(sa_setting_value).records.collect(&:id).include?(setting_value.to_i)
        data=StudentRecord.first(:conditions => {:student_id => id, :batch_id => batch_in_context_id, :additional_field_id => setting_value})
        CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => os, :data => data.present? ? data.additional_info : '')
      else
        CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => os, :data => '')
      end
    end
  end

  def generate_registration_no_copy
    keys = CceReportSetting.get_multiple_settings_as_hash(["RegistrationNo", "RegistrationNoVal"])
    if keys[:registration_no] == "1" and keys[:registration_no_val].present? and keys[:registration_no_val].to_i > 0
      reg_no = StudentAdditionalDetail.first(:conditions => {:student_id => id, :additional_field_id => keys[:registration_no_val].to_i, :student_additional_fields => {:status => true}}, :joins => :student_additional_field).try(:additional_info)
      CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => "RegistrationNoVal", :data => reg_no)
    end
  end

  def generate_eiop_settings_copy
    eiop_setting=EiopSetting.find_by_course_id(self.batch_in_context.course_id)
    if eiop_setting.present?
      CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => 'grade', :data => (eiop_setting.grade_point == "" ? CceReportSetting::FALLBACK_SETTINGS["grade"] : eiop_setting.grade_point))
      CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => 'pass_text', :data => (eiop_setting.pass_text == "" ? CceReportSetting::FALLBACK_SETTINGS["pass_text"] : eiop_setting.pass_text))
      CceReportSettingCopy.create(:student_id => id, :batch_id => batch_in_context_id, :setting_key => 'eiop_text', :data => (eiop_setting.eiop_text == "" ? CceReportSetting::FALLBACK_SETTINGS["eiop_text"] : eiop_setting.eiop_text))
    end
  end

  def create_student_cce_report_setting_copy
    generate_general_settings_copy
    generate_registration_no_copy
    generate_health_status_settings_copy
    generate_self_awareness_settings_copy
    generate_eiop_settings_copy
  end

  def delete_student_upscaled_values
    UpscaleScore.delete_all(["student_id = ? and batch_id = ?", id, batch_in_context_id])
  end

  def delete_student_scholastic_reports
    CceReport.delete_all(["student_id = ? and batch_id = ? AND cce_exam_category_id > 0", id, batch_in_context_id])
  end

  def create_student_scholastic_reports
    report_hash=Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    config_value=Configuration.find_by_config_key("CceFaType").try(:config_value) || "1"
    batch_in_context.subjects.each do |subject|
      subject.fa_groups.each do |fg|
        report_hash["config"][fg.id]["fg_max_marks"] = fg.max_marks
        if fg.criteria_formula.present?
          formula = fg.criteria_formula
        else
          if fg.fa_criterias.active.count > 1
            formula = "avg(#{fg.fa_criterias.active.collect(&:formula_key).join(',')},@#{fg.max_marks.to_i})"
          elsif fg.fa_criterias.active.count == 1
            formula = "#{fg.fa_criterias.active.first.formula_key}"
          end
        end
        report_hash["config"][fg.id]["fg_formula"] = formula
        fg.fa_criterias.active.all(:include => :assessment_scores).each do |f|
          report_hash["config"][fg.id][f.id]["fa_max_marks"] = f.max_marks
          report_hash["config"][fg.id][f.id]["indicator"] = f.formula_key
          f.assessment_scores.scoped(:conditions => ["cce_exam_category_id IS NOT NULL AND student_id = ? AND batch_id = ? and subject_id=?", id, batch_in_context_id, subject.id]).group_by(&:cce_exam_category_id).each do |k1, v1|
            v1.group_by(&:subject_id).each do |k2, v2|
              report_hash["students"][k1][k2][fg.id][f.id] = (fg.di_formula == 1 ? (((v2.sum(&:grade_points)/v2.count))).to_f : ((v2.sum(&:grade_points)).to_f))
            end
          end
        end
      end
    end
    report_hash["students"].each do |ck, cv|
      cv.each do |suk, suv|
        suv.each do |fgk, fgv|
          fa_obtained_score_hash={}
          fa_max_score_hash={}
          if config_value=="1"
            fgv.each do |k, v|
              hsh1={report_hash["config"][fgk][k]["indicator"] => (v.to_f)}
              fa_obtained_score_hash.merge! hsh1
            end
          else
            fgv.each do |k, v|
              hsh1={report_hash["config"][fgk][k]["indicator"] => (v.to_f/report_hash["config"][fgk][k]["fa_max_marks"].to_f)}
              fa_obtained_score_hash.merge! hsh1
            end
          end
          if config_value == "1"
            fgv.each do |k, v|
              hsh1={report_hash["config"][fgk][k]["indicator"] => (report_hash["config"][fgk][k]["fa_max_marks"].to_f)}
              fa_max_score_hash.merge! hsh1
            end
          else
            fgv.each do |k, v|
              hsh1={report_hash["config"][fgk][k]["indicator"] => 1}
              fa_max_score_hash.merge! hsh1
            end
          end
          config = config_value == "1" ? :tmm : :cdm
          if ExamFormula::formula_validate(report_hash["config"][fgk]["fg_formula"], config_value)
            equation = ExamFormula.new(report_hash["config"][fgk]["fg_formula"], :obtained_marks => fa_obtained_score_hash, :max_marks => fa_max_score_hash, :mode => config)
            if equation.valid?
              result = equation.calculate
              fa_group=FaGroup.find_by_id(fgk)
              converted_mark=result.into(100)
              obtained_mark=result.into(report_hash["config"][fgk]["fg_max_marks"].to_f)
              grade_string=to_grade(converted_mark)
              exam=Exam.first(:conditions => {:exam_groups => {:batch_id => batch_in_context_id, :cce_exam_category_id => ck}, :subject_id => suk}, :joins => :exam_group)
              unless exam.nil?
                fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :exam_id => exam.id, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
              else
                fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
              end
            else
              fa_group=FaGroup.find_by_id(fgk)
              converted_mark=obtained_mark=0.0
              grade_string=to_grade(converted_mark)
              exam=Exam.first(:conditions => {:exam_groups => {:batch_id => batch_in_context_id, :cce_exam_category_id => ck}, :subject_id => suk}, :joins => :exam_group)
              unless exam.nil?
                fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :exam_id => exam.id, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
              else
                fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
              end
            end
          else
            fa_group=FaGroup.find_by_id(fgk)
            converted_mark=obtained_mark=0.0
            grade_string=to_grade(converted_mark)
            exam=Exam.first(:conditions => {:exam_groups => {:batch_id => batch_in_context_id, :cce_exam_category_id => ck}, :subject_id => suk}, :joins => :exam_group)
            unless exam.nil?
              fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :exam_id => exam.id, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
            else
              fa_group.cce_reports.create(:student_id => id, :grade_string => grade_string, :batch_id => batch_in_context_id, :obtained_mark => obtained_mark.to_f, :converted_mark => converted_mark.to_f, :max_mark => report_hash["config"][fgk]["fg_max_marks"].to_f, :subject_id => suk, :cce_exam_category_id => ck)
            end
          end
        end
      end
    end
  end

  def delete_student_coscholastic_reports
    CceReport.delete_all({:student_id => id, :batch_id => batch_in_context_id, :cce_exam_category_id => nil})
  end

  def create_student_coscholastic_reports
    report_hash={}
    batch=Batch.find batch_in_context_id
    batch.observation_groups.scoped(:include => [{:observations => :assessment_scores}, {:cce_grade_set => :cce_grades}]).each do |og|
      og.observations.each do |o|
        report_hash[o.id]={}
        o.assessment_scores.scoped(:conditions => {:cce_exam_category_id => nil, :batch_id => batch_in_context_id, :student_id => id}).group_by(&:student_id).each { |k, v| report_hash[o.id][k]=(v.sum(&:grade_points)/v.count.to_f).round }
        report_hash[o.id].each do |key, val|
          o.cce_reports.build(:student_id => key, :grade_string => og.cce_grade_set.grade_string_for(val), :batch_id => batch_in_context_id)
        end
        o.save
      end
    end
  end


  def update_student_asl_scores
    batch=Batch.find batch_in_context_id
    if batch.asl_subject.present?
      self.asl_scores.all(:conditions => {:exam => {:subjects => {:batch_id => batch_in_context_id}}}, :joins => {:exam => :subject}, :readonly => false).each do |asl_score|
        sub= asl_score.exam.subject
        conversion=sub.asl_mark
        case conversion
        when 20
          final_score = ((asl_score.speaking.to_f + asl_score.listening.to_f)/2) * 5
          asl_score.update_attribute('final_score', final_score)
        when 10
          final_score = ((asl_score.speaking.to_f + asl_score.listening.to_f)/4) * 10
          asl_score.update_attribute('final_score', final_score)
        end
      end
    else
      self.asl_scores.all(:conditions => {:exam => {:subjects => {:batch_id => batch_in_context_id}}}, :joins => {:exam => :subject}).each do |e|
        e.destroy
      end
    end
  end

  def student_records_data
    student_records.each do |sr|
      if ["singleline", "multiline", "single_select", "multi_select", "date"].include?(sr.record.input_type) and sr.record.is_mandatory and (sr.additional_info == "" or sr.additional_info.nil?)
        errors.add(sr.record.name, :is_required)
      elsif sr.record.input_type == 'attachment' and sr.record.is_mandatory and sr.record_addl_attachments.reject { |o| (o._destroy==true if o._destroy) }.blank?
        errors.add(sr.record.name, :has_no_attachments)
      elsif sr.record.input_type == 'multi_select' and sr.record.is_mandatory and sr.additional_info.split(", ").reject { |s| s.blank? }.blank?
        errors.add(sr.record.name, :is_required)
      end
      if sr.record.input_type == 'singleline' and sr.additional_info.present?
        if sr.record.record_type == 'numeric'
          errors.add(sr.record.name, :has_to_be_numeric) if (sr.additional_info.match(/\A[+-]?\d+?(_?\d+)*(\.\d+e?\d*)?\Z/) == nil) == true
        end
      end
    end
  end

  def self.find_student_with_biometric(biometric_id)
    Student.all(
      :joins => [:user => [:biometric_information]],
      :conditions => {:biometric_informations => {:biometric_id => biometric_id}}
    )
  end

  def delete_nil_student_records
    self.student_records.each do |sr|
      sr.destroy if ((sr.additional_info.nil? or sr.additional_info.blank?) and !sr.record.input_type == 'attachment')
    end
  end

  def completion(batch_id, rg_id=nil)
    batch=Batch.find batch_id
    if rg_id.present?
      rg=RecordGroup.find(rg_id)
      all_records_count=rg.records.count
      student_records_count = self.student_records.count(:conditions => ["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=? and student_records.additional_field_id IN (?)) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=? and student_records.additional_field_id IN (?))", batch_in_context_id, rg.records.collect(&:id), batch_in_context_id, rg.records.collect(&:id)], :joins => "inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
      all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100).to_i
    else
      all_records_count=batch.record_batch_assignments.all(:include => :record_group).collect { |a| a.record_group.records.count }.sum
      record_groups=batch.course.record_groups.all(:select => "distinct record_groups.*", :joins => "INNER JOIN record_batch_assignments on record_batch_assignments.record_assignment_id = record_assignments.id INNER JOIN `records` ON record_groups.id = records.record_group_id LEFT OUTER JOIN `record_field_options` ON record_field_options.record_id = records.id")
      r_ids=[]
      record_groups.each do |rg|
        r_ids += rg.records.collect(&:id)
      end
      student_records_count=self.student_records.count(:conditions => ["(raa.attachment_file_name is not null and r.input_type='attachment' and student_records.batch_id=?) or (r.input_type <> 'attachment' and student_records.additional_info != '' and student_records.batch_id=?)", batch_in_context_id, batch_in_context_id], :joins => "inner join students s on s.id=student_records.student_id inner join records r on r.id=student_records.additional_field_id inner join record_groups rg on rg.id=r.record_group_id left outer join record_addl_attachments raa on raa.student_record_id=student_records.id inner join batches b on b.id=student_records.batch_id inner join courses c on c.id=b.course_id inner join record_assignments ra on ra.record_group_id =rg.id and ra.course_id=c.id inner join record_batch_assignments rba on rba.record_assignment_id=ra.id and rba.batch_id=b.id")
      all_records_count == 0 ? 0 : ((student_records_count.to_f/all_records_count.to_f)*100)
    end
  end

  
  def save_biometric_info
    biometric_info = BiometricInformation.find_or_initialize_by_user_id(user_id)
    biometric_info.update_attributes(:user_id => user_id, :biometric_id => biometric_id)
    biometric_info.errors.each { |attr, msg| errors.add(attr.to_sym, "#{msg}") }
    unless errors.blank?
      user_record = User.find_by_id(user_id)
      user_record.destroy if user_record.present?
      raise ActiveRecord::Rollback
    end
  end

  def handle_student_additional_data
    self.student_additional_details.destroy_all unless ArchivedStudent.find_by_former_id(self.id).present?
  end

  def handle_student_records_data
    self.student_records.destroy_all unless ArchivedStudent.find_by_former_id(self.id).present?
  end

  def update_cancelled_finance_transactions_details
    CancelledFinanceTransaction.find_in_batches(:batch_size => 500, :conditions => {:payee_id => self.id, :payee_type => 'Student'}) do |cfts|
      isql = "UPDATE `cancelled_finance_transactions` SET `other_details`= CASE"
      cft_ids = []
      if cfts.present?
        cfts.each do |cft|
          cft_ids << cft.id
          other_details = (cft.other_details.present? ? cft.other_details : {}).merge({:payee_name => ("#{self.full_name} #{self.admission_no}").gsub("'","''")})
          isql += " WHEN `id` = #{cft.id} THEN '#{other_details.to_yaml}' "
        end
        isql += "END WHERE `id` in (#{cft_ids.join(',')});"
        RecordUpdate.connection.execute(isql)
      end
    end
  end

  def validate
    errors.add(:admission_date, :not_less_than_hundred_year) if self.admission_date.year < Date.today.year - 100 \
      if self.admission_date.present?
    errors.add(:date_of_birth, :not_less_than_hundred_year) if self.date_of_birth.year < Date.today.year - 100 \
      if self.date_of_birth.present?
    errors.add(:admission_date, :not_less_than_date_of_birth) if self.admission_date < self.date_of_birth \
      if self.date_of_birth.present? and self.admission_date.present?
    errors.add(:date_of_birth, :cant_be_a_future_date) if self.date_of_birth >= Date.today \
      if self.date_of_birth.present?
    errors.add(:gender, :error2) unless ['m', 'f'].include? self.gender.downcase \
      if self.gender.present?
    errors.add(:admission_no, :error3) if self.admission_no=='0'
    errors.add(:admission_no, :should_not_be_admin) if self.admission_no.to_s.downcase== 'admin'
    unless student_additional_details.blank?
      student_additional_details.each do |student_additional_detail|
        errors.add_to_base(student_additional_detail.errors.full_messages.map { |e| e.to_s+". Please add additional details." }.join(', ')) unless student_additional_detail.valid?
      end
    end
  end

  def is_active_true
    unless self.is_active==1
      self.is_active=1
    end
  end

  def update_roll_number
    if self.roll_number.present? && self.batch.present?
      batch_prefix = self.batch.get_roll_number_prefix || ""
      self.roll_number.to_s.slice!(batch_prefix.to_s)
      self.roll_number = batch_prefix + self.roll_number.to_s if self.roll_number.to_s.present?
    end
  end

  def create_user_and_validate
    if self.new_record?
      if self.user.present?
        self.user.activate
      else
        user_record = self.build_user
        user_record.first_name = self.first_name
        user_record.last_name = self.last_name
        user_record.username = self.admission_no.to_s
        user_record.password = self.admission_no.to_s + "123"
        user_record.role = 'Student'
        user_record.email = self.email.blank? ? "" : self.email.to_s
        check_user_errors(user_record)
        return false unless errors.blank?
      end
    else

      self.user.role = "Student"
      changes_to_be_checked = ['admission_no', 'first_name', 'last_name', 'email', 'immediate_contact_id']
      check_changes = self.changed & changes_to_be_checked
      unless check_changes.blank?
        self.user.username = self.admission_no if check_changes.include?('admission_no')
        self.user.first_name = self.first_name if check_changes.include?('first_name')
        self.user.last_name = self.last_name if check_changes.include?('last_name')
        self.user.email = self.email if check_changes.include?('email')
        self.user.password = (self.admission_no.to_s + "123") if check_changes.include?('admission_no')
        self.user.save if check_user_errors(self.user)
      end

      if check_changes.include?('immediate_contact_id') or check_changes.include?('admission_no')
        Guardian.shift_user(self)
      end

    end
    self.email = "" if self.email.blank?
    return false unless errors.blank?
  end

  def check_user_errors(user)
    unless user.valid?
      er_attrs = []
      errors.each do |a, m|
        er_attrs.push([t(a.to_sym), "#{m}"])
      end
      user.errors.each { |attr, msg| errors.add(t(attr.to_sym), "#{msg}") unless er_attrs.include?([t(attr.to_sym), "#{msg}"]) }
    end
    user.errors.blank?
  end

  def first_and_last_name
    "#{first_name} #{last_name}"
  end

  def full_name
    "#{first_name} #{middle_name} #{last_name}"
  end

  def full_address
    "#{address_line1} #{address_line2} #{city} #{state} #{pin_code}"
  end
  
  def student_attendance
    attendance_label = AttendanceLabel.find_by_attendance_type('Late')
    batch=self.batch
    student_term_attendance=Array.new
    term_dates=batch.exam_groups.all(:select => "min(exams.start_time) as term1_end_date,max(exams.end_time) as term2_end_date", :joins => :exams)
    start_date = batch.start_date.to_date
    end_date=term_dates.first.term1_end_date.to_date
    2.times do
      student_attendances=Hash.new
      academic_days=batch.academic_days.count
      leaves_forenoon=Attendance.count(:all, :conditions => {:batch_id => batch_in_context_id, :forenoon => true, :afternoon => false, :month_date => start_date..end_date}, :group => :student_id)
      leaves_afternoon=Attendance.count(:all, :conditions => {:batch_id => batch_in_context_id, :forenoon => false, :afternoon => true, :month_date => start_date..end_date}, :group => :student_id)
      leaves_full=Attendance.count(:all, :conditions => {:batch_id => batch_in_context_id, :forenoon => true, :afternoon => true, :month_date => start_date..end_date}, :group => :student_id)
      #  leaves_full=Attendance.count(:all, :conditions => ["batch_id = #{batch_in_context_id}  and forenoon = #{true} and  afternoon = #{true} and  month_date = #{start_date..end_date} and attendance_label_id != #{attendance_label.id}"], :group => :student_id)
      attendance=academic_days-leaves_full[self.id].to_f-(0.5*(leaves_forenoon[self.id].to_f+leaves_afternoon[self.id].to_f))
      student_attendances[:total_day]=academic_days
      student_attendances[:total_attendance]=attendance
      student_term_attendance.push(student_attendances)
      start_date =term_dates.first.term2_end_date.to_date
      end_date = batch.end_date.to_date
    end
    return student_term_attendance
  end

  def father_name
    father_name=self.guardians.first(:conditions => {:relation => "father"})
    father_name.present? ? father_name.full_name : nil
  end
  
  def mother_name
    mother_name=self.guardians.first(:conditions => {:relation => "mother"})
    mother_name.present? ? mother_name.full_name : nil
  end

  def guardian_name
    father_name=self.guardians.first(:conditions => {:relation => "father"})
    unless father_name.present?
      guardian=self.guardians.first(:conditions => ["relation != 'father' and relation != 'mother'"])
      if guardian.present?
        return "#{guardian.full_name}"+" (#{guardian.translated_relation})"
      else
        return
      end
    end
    return father_name.full_name
  end

  def guardian_id
    father_name=self.guardians.first(:conditions => {:relation => "father"})
    unless father_name.present?
      guardian=self.guardians.first(:conditions => ["relation != 'father' and relation != 'mother'"])
      if guardian.present?
        return "#{guardian.user_id}"
      else
        return
      end
    end
    return father_name.user_id
  end
  
  def father_no
    father_name=self.guardians.first(:conditions => {:relation => "father"})
    father_name.present? ? father_name.try(:mobile_phone) : nil
  end
  
  def mother_no
    mother_name=self.guardians.first(:conditions => {:relation => "mother"})
    mother_name.present? ? mother_name.try(:mobile_phone) : nil
  end
  
  def batch_name
    batch.name
  end
   
  def gender_as_text
    return 'Male' if gender.downcase == 'm'
    return 'Female' if gender.downcase == 'f'
    nil
  end

  def graduated_batches
    self.batch_students.map { |bt| bt.batch }
  end
  
  def graduated_cce_batches
    self.all_batches.map { |b| b if b.cce_enabled?}.reject{|a| a.nil? }
  end
  
  def graduated_icse_batches
    self.all_batches.map { |b| b if b.icse_enabled?}.reject{|a| a.nil? }
  end
  
  def graduated_normal_batches
    self.all_batches.map { |b| b if b.normal_enabled?}.reject{|a| a.nil? }
  end

  def all_batches
    self.graduated_batches + self.batch.to_a
  end

  def image_file=(input_data)
    return if input_data.blank?
    self.photo_filename = input_data.original_filename
    self.photo_content_type = input_data.content_type.chomp
    self.photo_data = input_data.read
  end

  def next_student
    next_st = self.batch.students.first(:conditions => "id > #{self.id}", :order => "id ASC")
    next_st ||= batch.students.first(:order => "id ASC")
  end

  def previous_student
    prev_st = self.batch.students.first(:conditions => "id < #{self.id}", :order => "admission_no DESC")
    prev_st ||= batch.students.first(:order => "id DESC")
    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def previous_fee_student(date, student_batch_id)
    fee = FinanceFee.first(:conditions => "student_id < #{self.id} and fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id DESC")
    prev_st = fee.student unless fee.blank?
    fee ||= FinanceFee.first(:conditions => "fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id DESC")
    prev_st ||= fee.student unless fee.blank?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def next_fee_student(date, student_batch_id)
    fee = FinanceFee.first(:conditions => "student_id > #{self.id} and fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id ASC")
    next_st = fee.student unless fee.nil?
    fee ||= FinanceFee.first(:conditions => "fee_collection_id = #{date} and FIND_IN_SET(students.id,'#{student_batch_id}')", :joins => 'INNER JOIN students ON finance_fees.student_id = students.id', :order => "student_id ASC")
    next_st ||= fee.student unless fee.nil?
    #    prev_st ||= self.batch.students.first(:order => "id DESC")
  end

  def exam_retaken(exam_id)
    if self.previous_exam_scores.find_by_exam_id(exam_id).present?
      return true
    else
      return false
    end
  end

  def finance_fee_by_date(date, inc_fee_assoc = {})
    # NOTE::
    # readonly false is used to allow update on the returned object
    FinanceFee.last(
      :conditions => ["fee_collection_id = ? AND student_id = ? AND (ffc.fee_account_id IS NULL OR fa.is_deleted = false)", date.id, self.id],
      :joins => "INNER JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                  LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id",
      :include => { :finance_transactions => :transaction_ledger }.merge(inc_fee_assoc),
      :readonly => false
    )
  end

  def fee_by_date(date, model_name, inc_fee_assoc = {})    
    tbl_name = model_name.table_name
    collection_name = date.class.name.underscore
    collection_name = "fee_collection" if model_name == FinanceFee
    if model_name == TransportFee      
      conditions = "#{tbl_name}.receiver_id = #{id} and #{tbl_name}.receiver_type = 'Student' AND
                    #{tbl_name}.#{collection_name}_id = #{date.id}"
    else
      conditions = "#{tbl_name}.student_id = #{id} and 
                    #{tbl_name}.#{collection_name}_id = #{date.id}"          
    end
    model_name.find(:last, :conditions => conditions,
      :include => [{ :finance_transactions => :transaction_ledger }.
          merge(inc_fee_assoc), :fee_invoices])
  end
  
  def check_fees_paid(date)
    particulars = date.fees_particulars(self)
    total_fees=0
    financefee = date.fee_transactions(self.id)
    batch_discounts = BatchFeeCollectionDiscount.find_all_by_finance_fee_collection_id(date.id)
    student_discounts = StudentFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id, self.id)
    category_discounts = StudentCategoryFeeCollectionDiscount.find_all_by_finance_fee_collection_id_and_receiver_id(date.id, self.student_category_id)
    total_discount = 0
    total_discount += batch_discounts.map { |s| s.discount }.sum unless batch_discounts.nil?
    total_discount += student_discounts.map { |s| s.discount }.sum unless student_discounts.nil?
    total_discount += category_discounts.map { |s| s.discount }.sum unless category_discounts.nil?
    if total_discount > 100
      total_discount = 100
    end
    particulars.map { |s| total_fees += s.amount.to_f }
    total_fees -= total_fees*(total_discount/100)
    paid_fees_transactions = FinanceTransaction.find(:all, :select => 'amount,fine_amount', :conditions => "FIND_IN_SET(id,\"#{financefee.transaction_id}\")") unless financefee.nil?
    paid_fees = 0
    paid_fees_transactions.map { |m| paid_fees += (m.amount.to_f - m.fine_amount.to_f) } unless paid_fees_transactions.nil?
    amount_pending = total_fees.to_f - paid_fees.to_f
    if amount_pending == 0
      return true
    else
      return false
    end

    #    unless particulars.nil?
    #      return financefee.check_transaction_done unless financefee.nil?
    #
    #    else
    #      return false
    #    end
  end

  def has_retaken_exam(subject_id)
    retaken_exams = PreviousExamScore.find_all_by_student_id(self.id)
    if retaken_exams.empty?
      return false
    else
      exams = Exam.find_all_by_id(retaken_exams.collect(&:exam_id))
      if exams.collect(&:subject_id).include?(subject_id)
        return true
      end
      return false
    end

  end

  def check_fee_pay(date)
    FedenaPrecision.set_and_modify_precision(date.finance_fees.first(:conditions => "student_id = #{self.id}").balance).to_f == FedenaPrecision.set_and_modify_precision(0).to_f
  end

  def self.next_admission_no
    '' #stub for logic to be added later.
  end

  def get_fee_strucure_elements(date)
    elements = FinanceFeeStructureElement.get_student_fee_components(self, date)
    elements[:all] + elements[:by_batch] + elements[:by_category] + elements[:by_batch_and_category]
  end

  def total_fees(particulars)
    total = 0
    particulars.each do |fee|
      total += fee.amount
    end
    total
  end

  def has_associated_fee_particular?(fee_category)
    status = false
    status = true if fee_category.fee_particulars.find(:all, :conditions => {:admission_no => admission_no, :is_deleted => false}).count > 0
    status = true if student_category_id.present? and fee_category.fee_particulars.find(:all, :conditions => {:student_category_id => student_category_id, :is_deleted => false}).count > 0
    return status
  end

  def archive_student(status, leaving_date)
    student_attributes = self.attributes
    student_attributes["former_id"]= self.id
    student_attributes["status_description"] = status
    student_attributes["former_has_paid_fees"] = self.has_paid_fees
    student_attributes["former_has_paid_fees_for_batch"] = self.has_paid_fees_for_batch
    student_attributes.merge!(:sibling_id => sibling_id)
    student_attributes.delete "id"
    student_attributes.delete "has_paid_fees"
    student_attributes.delete "has_paid_fees_for_batch"
    student_attributes.delete "created_at"
    archived_student = ArchivedStudent.new(student_attributes)
    archived_student.photo = self.photo if self.photo.file?
    archived_student.date_of_leaving = leaving_date
    ActiveRecord::Base.transaction do
      if archived_student.save
        guardians = self.guardians
        self.user.soft_delete
        if archived_student.siblings.present?
          archived_guardians=archived_student.archived_guardians
          archived_guardians.each do |ag|
            ag.destroy
          end
        end
        guardians.each do |g|
          g.archive_guardian(archived_student.id, self.id)
        end
        self.destroy
      end
    end
  end

  def check_dependency
    return true if self.students_subjects.present? or self.finance_transactions.present? or self.graduated_batches.present? or self.attendances.present? or self.finance_fees.active.present? or Exam.find(:all, :joins => :exam_scores, :conditions => {:exam_scores => {:student_id => self.id}}).present? or self.subject_leaves.present? or self.assessment_scores.present? or self.cce_reports.present?
    return true if FedenaPlugin.check_dependency(self, "permanant").present?
    return false
  end

  def student_dependencies_list
    warning_msgs = []
    warning_msgs << "#{t('finance_records_present')}" if self.finance_transactions.present? or self.finance_fees.active.present?
    warning_msgs << "#{t('graduated_batch_present')}" if self.graduated_batches.present?
    warning_msgs << "#{t('attendance_are_already_marked')}" if self.attendances.present? or self.subject_leaves.present?
    warning_msgs << "#{t('already_appeared_for_exam')}" if Exam.find(:all, :joins => :exam_scores, :conditions => {:exam_scores => {:student_id => self.id}}).present? or self.assessment_scores.present? or self.cce_reports.present?
    warning_msgs << "#{t('elective_subjects_are_assigned')}" if self.students_subjects.present?
    plugins = []
    FedenaPlugin::AVAILABLE_MODULES.each do |mod|
      plugins << (mod[:name] + "_dependency").to_sym
    end
    DependencyHook.check_dependency_for(self, :only => plugins).each do |dependency|
      warning_msgs << dependency.warning unless dependency.result
    end
    return warning_msgs
  end

  def former_dependency
    plugin_dependencies = FedenaPlugin.check_dependency(self, "former")
  end

  def assessment_score_for(indicator_id, subject_id, cce_exam_category_id, batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => {:student_id => self.id, :descriptive_indicator_id => indicator_id, :subject_id => subject_id, :cce_exam_category_id => cce_exam_category_id, :batch_id => batch_id})
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id => indicator_id, :subject_id => subject_id, :cce_exam_category_id => cce_exam_category_id, :batch_id => batch_id) : assessment_score
  end

  def observation_score_for(indicator_id, batch_id)
    assessment_score = self.assessment_scores.find(:first, :conditions => {:student_id => self.id, :descriptive_indicator_id => indicator_id, :batch_id => batch_id})
    assessment_score.nil? ? assessment_scores.build(:descriptive_indicator_id => indicator_id, :batch_id => batch_id) : assessment_score
  end

  #  def create_default_menu_links
  #    default_links = MenuLink.find_all_by_user_type("student")
  #    self.user.menu_links = default_links
  #  end
  def has_completed_assessment(observation_group, batch)
    completed = true
    indicators_count = 0
    observation_group.observations.each do |observation|
      indicators_count = indicators_count + observation.descriptive_indicators.count
      if CceReportSetting.get_setting_value('ObservationRemarkMode') == "0"
        remark = self.student_coscholastic_remarks.find_by_observation_id observation.id
        if remark.nil?
          completed = false
        elsif remark.remark.blank?
          completed = false
        end
      end
    end
    di=observation_group.observations.collect(&:descriptive_indicator_ids).flatten
    scores_count = self.assessment_scores.find(:all, :conditions => {:student_id => self.id, :batch_id => batch.id, :descriptive_indicator_id => di}).count
    unless scores_count == indicators_count
      completed = false
    end
    return completed
  end

  def has_higher_priority_ranking_level(ranking_level_id, type, subject_id)
    ranking_level = RankingLevel.find(ranking_level_id)
    higher_levels = RankingLevel.find(:all, :conditions => ["course_id = ? AND priority < ?", ranking_level.course_id, ranking_level.priority])
    if higher_levels.empty?
      return false
    else
      higher_levels.each do |level|
        if type=="subject"
          score = GroupedExamReport.find_by_student_id_and_subject_id_and_batch_id_and_score_type(self.id, subject_id, self.batch_id, "s")
          unless score.nil?
            if self.batch.gpa_enabled?
              return true if ((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
            else
              return true if ((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
            end
          end
        elsif type=="overall"
          unless level.subject_count.nil?
            unless level.full_course==true
              subjects = self.batch.subjects
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => self.id, :batch_id => self.batch_in_context_id, :subject_id => subjects.collect(&:id), :score_type => "s"})
            else
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => self.id, :score_type => "s"})
            end
            unless scores.empty?
              if self.batch.gpa_enabled?
                scores.reject! { |s| !((s.marks < level.gpa if level.marks_limit_type=="upper") or (s.marks >= level.gpa if level.marks_limit_type=="lower") or (s.marks == level.gpa if level.marks_limit_type=="exact")) }
              else
                scores.reject! { |s| !((s.marks < level.marks if level.marks_limit_type=="upper") or (s.marks >= level.marks if level.marks_limit_type=="lower") or (s.marks == level.marks if level.marks_limit_type=="exact")) }
              end
              unless scores.empty?
                sub_count = level.subject_count
                if level.subject_limit_type=="upper"
                  return true if scores.count < sub_count
                elsif level.subject_limit_type=="exact"
                  return true if scores.count == sub_count
                else
                  return true if scores.count >= sub_count
                end
              end
            end
          else
            unless level.full_course==true
              score = GroupedExamReport.find_by_student_id(self.id, :conditions => {:batch_id => self.batch_in_context_id, :score_type => "c"})
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id, "c")
              unless marks.empty?
                marks.map { |m| total_student_score+=m.marks }
                avg_student_score = total_student_score.to_f/marks.count.to_f
                marks.first.marks = avg_student_score
                score = marks.first
              end
            end
            unless score.nil?
              if self.batch.gpa_enabled?
                return true if ((score.marks < level.gpa if level.marks_limit_type=="upper") or (score.marks >= level.gpa if level.marks_limit_type=="lower") or (score.marks == level.gpa if level.marks_limit_type=="exact"))
              else
                return true if ((score.marks < level.marks if level.marks_limit_type=="upper") or (score.marks >= level.marks if level.marks_limit_type=="lower") or (score.marks == level.marks if level.marks_limit_type=="exact"))
              end
            end
          end
        elsif type=="course"
          batches = self.batch.course.active_batches
          unless level.subject_count.nil?
            scores = GroupedExamReport.find(:all, :conditions => {:student_id => self.id, :batch_id => batches.collect(&:id), :score_type => "s"})
            unless scores.empty?
              if level.marks_limit_type=="upper"
                scores.reject! { |s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?)) }
              elsif level.marks_limit_type=="exact"
                scores.reject! { |s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?)) }
              else
                scores.reject! { |s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?)) }
              end
              unless scores.empty?
                sub_count = level.subject_count
                unless level.full_course==true
                  batch_ids = scores.collect(&:batch_id)
                  batch_ids.each do |batch_id|
                    unless batch_ids.empty?
                      count = batch_ids.count(batch_id)
                      if level.subject_limit_type=="upper"
                        return true if count < sub_count
                      elsif level.subject_limit_type=="exact"
                        return true if count == sub_count
                      else
                        return true if count >= sub_count
                      end
                      batch_ids.delete(batch_id)
                    end
                  end
                else
                  if level.subject_limit_type=="upper"
                    return true if scores.count < sub_count
                  elsif level.subject_limit_type=="exact"
                    return true if scores.count == sub_count
                  else
                    return true if scores.count >= sub_count
                  end
                end
              end
            end
          else
            unless level.full_course==true
              scores = GroupedExamReport.find(:all, :conditions => {:student_id => self.id, :batch_id => batches.collect(&:id), :score_type => "c"})
              unless scores.empty?
                if level.marks_limit_type=="upper"
                  scores.reject! { |s| !(((s.marks < level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks < level.marks unless level.marks.nil?)) }
                elsif level.marks_limit_type=="exact"
                  scores.reject! { |s| !(((s.marks == level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks == level.marks unless level.marks.nil?)) }
                else
                  scores.reject! { |s| !(((s.marks >= level.gpa unless level.gpa.nil?) if s.student.batch.gpa_enabled?) or (s.marks >= level.marks unless level.marks.nil?)) }
                end
                return true unless scores.empty?
              end
            else
              total_student_score = 0
              avg_student_score = 0
              marks = GroupedExamReport.find_all_by_student_id_and_score_type(self.id, "c")
              unless marks.empty?
                marks.map { |m| total_student_score+=m.marks }
                avg_student_score = total_student_score.to_f/marks.count.to_f
                if level.marks_limit_type=="upper"
                  return true if (((avg_student_score < level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score < level.marks unless level.marks.nil?))
                elsif level.marks_limit_type=="exact"
                  return true if (((avg_student_score == level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score == level.marks unless level.marks.nil?))
                else
                  return true if (((avg_student_score >= level.gpa unless level.gpa.nil?) if self.batch.gpa_enabled?) or (avg_student_score >= level.marks unless level.marks.nil?))
                end
              end
            end
          end
        end
      end
    end
    return false
  end

  def get_profile_data
    student = self
    biometric_id = BiometricInformation.find_by_user_id(user_id).try(:biometric_id)
    additional_data = Hash.new
    additional_fields = StudentAdditionalField.all(:conditions => "status = true")
    additional_fields.each do |additional_field|
      detail = StudentAdditionalDetail.find_by_additional_field_id_and_student_id(additional_field.id, student.try(:id))
      additional_data[additional_field.name] = detail.try(:additional_info)
    end
    [student, additional_data, biometric_id]
  end

  def siblings
    @siblings ||= (self.class.find_all_by_sibling_id_and_immediate_contact_id(sibling_id, self.immediate_contact_id) - [self])
  end

  def all_siblings
    self.class.find_all_by_sibling_id(sibling_id)-[self]
  end

  def old_batch
    "#{ Batch.find(changes["batch_id"].last).full_name}"
  end

  def new_batch
    Batch.find(changes["batch_id"].first).full_name
  end

  #  def guardians_with_siblings
  #    if siblings.present?
  #      self.class.first(:select=>"students.*,count(guardians.id) as gc",
  #        :conditions=>["students.id IN (?)",siblings.collect(&:id)+[id]],
  #        :joins=>:guardians).try(:guardians_without_siblings) || guardians_without_siblings
  #    else
  #      guardians_without_siblings
  #    end
  #  end
  #  alias_method_chain :guardians,:siblings

  def set_sibling
    Student.connection.execute("UPDATE `students` SET `sibling_id` = '#{id}' WHERE `id` = #{id};")
  end

  def self.students_details (parameters)
    subject_id=parameters[:subject_id]
    sort_order=parameters[:sort_order]
    if subject_id.nil?
      if sort_order.nil?
        students= Student.all(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :order => 'first_name ASC')
      else
        students= Student.all(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :order => sort_order)
      end
    else
      if sort_order.nil?
        students= Student.all(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id", :group => 'students.id', :conditions => ["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id", subject_id], :order => 'first_name ASC')
      else
        students= Student.all(:select => "students.id,roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name, courses.course_name,courses.code,courses.section_name,courses.id as course_id,batches.id as batch_id,students.id as student_id ,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id INNER JOIN `students_subjects` ON students_subjects.student_id = students.id", :group => 'students.id', :conditions => ["students_subjects.subject_id=? and students.batch_id=students_subjects.batch_id", subject_id], :order => sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('admission_date') }", "#{t('batch_name')}", "#{t('course_name')}", "#{t('gender')}", "#{t('fees_paid')}"]
    col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    students.each_with_index do |obj, i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << obj.roll_number if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      col << "#{obj.batch_name}"
      col << "#{obj.course_name} #{obj.code}-#{obj.section_name}"
      col << "#{obj.gender.downcase=='m' ? t('m') : t('f')}"
      if obj.fee_count.to_i!= 0
        col<< t('no_texts')
      elsif obj.finance_transactions.empty?
        col<< t('na_text')
      else
        col<< t('yes_text')
      end
      col=col.flatten
      data << col
    end
    return data
  end

  def self.batch_wise_students (parameters)
    attendance_lock = AttendanceSetting.is_attendance_lock
    sort_order=parameters[:sort_order]
    batch_id=parameters[:batch_id]
    gender=parameters[:gender]
    batch=Batch.find batch_id
    month_date=batch.start_date.to_date
    end_date=Time.now.to_date
    config=Configuration.find_by_config_key('StudentAttendanceType')
    unless config.config_value == 'Daily'
      academic_days=batch.subject_hours(month_date, end_date, 0).values.flatten.compact.count
      unless gender.present?
        if sort_order.nil?
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => batch_id}, :order => 'first_name ASC')
        else
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => batch_id}, :order => sort_order)
        end
      else
        if sort_order.nil?
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE?", batch_id, gender], :order => 'first_name ASC')
        else
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,(#{academic_days}-count(DISTINCT IF(subject_leaves.month_date>=#{month_date} and subject_leaves.batch_id=#{batch_id},subject_leaves.id,NULL)))/#{academic_days}*100 as percent, count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN subject_leaves ON subject_leaves.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE?", batch_id, gender], :order => sort_order)
        end
      end
    else
      academic_days=batch.academic_days.count
      unless gender.present?
        if sort_order.nil?
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => batch_id}, :order => 'first_name ASC')
        else
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => {:batch_id => batch_id}, :order => sort_order)
        end
      else
        if sort_order.nil?
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE ?", batch_id, gender], :order => 'first_name ASC')
        else
          students= Student.all(:select => "students.id,roll_number,admission_date,first_name,middle_name,last_name,admission_no,gender,has_paid_fees ,(#{academic_days}-count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=1 and attendances.batch_id=#{batch_id},attendances.id,NULL))-(0.5*(count(DISTINCT IF(attendances.forenoon=1 and attendances.afternoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL))+count(DISTINCT IF(attendances.afternoon=1 and attendances.forenoon=0 and attendances.batch_id=#{batch_id},attendances.id,NULL)))))/#{academic_days}*100 as percent,count(IF(finance_fees.is_paid=0 ,1,NULL)) as fee_count", :joins => 'LEFT OUTER JOIN attendances ON attendances.student_id=students.id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id', :group => 'students.id', :conditions => ["students.batch_id=? AND students.gender LIKE ?", batch_id, gender], :order => sort_order)
        end
      end
    end
    data=[]
    unless gender.present?
      col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('admission_date') }", "#{t('gender')}", "#{t('attendance')}", "#{t('fees_paid')}"]
      col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    else
      col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('admission_date') }", "#{t('attendance')}", "#{t('fees_paid')}"]
      col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    end
    data << col_heads
    students.each_with_index do |obj, i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << obj.roll_number if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      unless gender.present?
        col << "#{obj.gender.downcase=='m' ? t('m') : t('f')}"
      end
      unless attendance_lock
        col << "#{obj.percent.to_f.round(2)}"
      else
        percent = student_attendance_percent(config.config_value,batch,obj,end_date,month_date)
        col << "#{percent.present? ? percent.round(2) : 0}"
      end
      if obj.fee_count.to_i!= 0
        col<< t('no_texts')
      elsif obj.finance_transactions.empty?
        col<< t('na_text')
      else
        col<< t('yes_text')
      end
      col=col.flatten
      data << col
    end
    return data
  end

  def self.student_attendance_percent(config,batch,student,end_date,month_date)
    if config == 'Daily'
      percent = student_dailywise_attendance(batch,student,end_date,month_date)
      return percent
    elsif config == 'SubjectWise'
      percent = student_subjectwise_attendance(batch,student,end_date,month_date)
      return percent
    end
  end
  
  def self.student_subjectwise_attendance(batch,student,end_date,month_date)
    elective_academic_days = []
    academic_days = MarkedAttendanceRecord.subject_wise_working_days(batch).select{|v| v <= end_date and  v >= month_date}
    elective_groups = batch.elective_groups.active
    elective_groups.each do |es|
      elective_academic_days = MarkedAttendanceRecord.subject_wise_elective_working_days(batch.id,es).select{|v| v <= end_date and  v >= month_date}
    end
    academic_days = academic_days + elective_academic_days
    leaves = SubjectLeave.find(:all,:conditions =>["student_id =? and batch_id=? and month_date IN (?)",student.id,batch.id,academic_days.flatten])
    leaves = leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    academic_days_count = (academic_days.flatten.count).to_f
    percent = academic_days.present? ? ((academic_days_count -leaves.to_f)/academic_days_count)*100 : 0
    return percent
  end
  
  def self.student_dailywise_attendance(batch,student,end_date,month_date)
    academic_days = MarkedAttendanceRecord.dailywise_working_days(batch.id).select{|v| v <= end_date and  v >= month_date}
    full_leaves = Attendance.all(:conditions =>["batch_id = ? and student_id = ? and forenoon= ? and afternoon= ? and month_date IN (?)",batch.id,student.id,true,true,academic_days])
    leaves_forenoon = Attendance.all(:conditions=>["batch_id = ? and student_id = ? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch.id,student.id,true,false,academic_days])
    leaves_afternoon = Attendance.all(:conditions=>["batch_id = ? and student_id = ? and forenoon = ? and afternoon = ? and  month_date IN (?)",batch.id,student.id,false,true,academic_days])
    leaves_forenoon = leaves_forenoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    leaves_afternoon = leaves_afternoon.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    full_leaves = full_leaves.to_a.reject{|sl| sl.attendance_label.try(:attendance_type) == "Late"}.count
    total_leaves = full_leaves.to_f + (0.5*(leaves_forenoon.to_f+leaves_afternoon.to_f)) 
    academic_days_count = (academic_days.count).to_f
    percent = academic_days.present? ? ((academic_days_count -total_leaves.to_f)/academic_days_count)*100 : 0
    return percent
  end
  
  def self.course_wise_students(parameters)
    sort_order=parameters[:sort_order]
    course_id=parameters[:course_id]
    gender=parameters[:gender]
    unless gender.present?
      if sort_order.nil?
        students= Student.all(:select => "roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => {:courses => {:id => course_id}}, :order => 'first_name ASC')
      else
        students= Student.all(:select => "roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => {:courses => {:id => course_id}}, :order => sort_order)
      end
    else
      if sort_order.nil?
        students= Student.all(:select => "roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => ["courses.id=? AND students.gender LIKE ?", course_id, gender], :order => 'first_name ASC')
      else
        students= Student.all(:select => "roll_number,first_name,middle_name,last_name,admission_no,admission_date,gender,has_paid_fees,CONCAT(courses.code,'-',batches.name) as batch_name,count(IF(finance_fees.is_paid=0 and finance_fee_collections.is_deleted=0,1,NULL)) as fee_count", :joins => "INNER JOIN `batches` ON `batches`.id = `students`.batch_id INNER JOIN `courses` ON `courses`.id = `batches`.course_id LEFT OUTER JOIN finance_fees ON finance_fees.student_id = students.id LEFT OUTER JOIN finance_fee_collections ON finance_fee_collections.id = finance_fees.fee_collection_id", :group => 'students.id', :conditions => ["courses.id=? AND students.gender LIKE ?", course_id, gender], :order => sort_order)
      end
    end
    data=[]
    unless gender.present?
      col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('admission_date') }", "#{t('batch_name')}", "#{t('gender')}", "#{t('fees_paid')}"]
      col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    else
      col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('admission_date') }", "#{t('batch_name')}", "#{t('fees_paid')}"]
      col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    end
    data << col_heads
    students.each_with_index do |obj, i|
      col=[]
      col << "#{i+1}"
      col << "#{obj.full_name}"
      col << "#{obj.roll_number}" if Configuration.enabled_roll_number?
      col << "#{obj.admission_no}"
      col << "#{format_date(obj.admission_date)}"
      col << "#{obj.batch_name}"
      unless gender.present?
        col << "#{obj.gender.downcase=='m' ? t('m') : t('f')}"
      end
      if obj.fee_count.to_i!= 0
        col<< t('no_texts')
      elsif obj.finance_transactions.empty?
        col<< t('na_text')
      else
        col<< t('yes_text')
      end
      col=col.flatten
      data << col
    end
    return data
  end

  def self.students_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]
    fee_collection_id=parameters[:fee_collection_id]
    batch_id=parameters[:batch_id]
    transaction_class=parameters[:transaction_class]
    if sort_order.nil?
      if transaction_class=="HostelFeeCollection"
        students=Student.all(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => [:hostel_fees],
          :conditions => ["hostel_fees.hostel_fee_collection_id=? and hostel_fees.balance !=? and students.batch_id=? AND `hostel_fees`.`is_active` = true", fee_collection_id, 0.0, batch_id],
          :order => "balance DESC")
      elsif transaction_class=="TransportFeeCollection"
        students=Student.all(
          :select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance",
          :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id",
          :conditions => ["transport_fees.transport_fee_collection_id=? and transport_fees.balance !=? and students.batch_id=? AND `transport_fees`.`is_active` = true", fee_collection_id, 0.0, batch_id],
          :order => "balance DESC")
      else
        students=Student.all(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?", fee_collection_id, 0.0, batch_id], :order => "balance DESC")
      end
    else
      if transaction_class=="HostelFeeCollection"
        students=Student.all(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => [:hostel_fees], :conditions => ["hostel_fees.hostel_fee_collection_id=? and  hostel_fees.balance !=? and students.batch_id=?", fee_collection_id, 0.0, batch_id], :order => sort_order)
      elsif transaction_class=="TransportFeeCollection"
        students=Student.all(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => "INNER JOIN transport_fees on transport_fees.receiver_id=students.id", :conditions => ["transport_fees.transport_fee_collection_id=? and  transport_fees.balance !=? and students.batch_id=?", fee_collection_id, 0.0, batch_id], :order => sort_order)
      else
        students=Student.all(:select => "students.roll_number,students.id,students.first_name,students.middle_name,students.last_name,students.admission_no,students.admission_date,balance", :joins => [:finance_fees], :conditions => ["finance_fees.fee_collection_id=? and finance_fees.balance !=? and finance_fees.batch_id=?", fee_collection_id, 0.0, batch_id], :order => sort_order)
      end
    end
    data=[]
    col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no')}", "#{t('admission_date')}", "#{t('balance')}(#{ Configuration.currency})"]
    col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    total=0
    students.each_with_index do |s, i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col<< s.roll_number if Configuration.enabled_roll_number?
      col<< "#{s.admission_no}"
      col<< "#{format_date(s.admission_date)}"
      balance=s.balance.nil? ? 0 : s.balance
      total+=balance.to_f
      col<< "#{balance}"
      col=col.flatten
      data<< col
    end
    data << ["#{t('total_amount')}", "", "", "", "", total]
    return data
  end

  def self.students_wise_fee_defaulters(parameters)
    sort_order=parameters[:sort_order]||nil
    columns = parameters[:columns] || {}
    additional_fields = StudentAdditionalField.get_fields
    students=Student.all(:select => 'students.roll_number,students.id,students.admission_no,students.first_name,students.middle_name,students.last_name,students.batch_id,sum(balance) balance,count(IF(balance>0,balance,NULL)) fee_collections_count, students.immediate_contact_id, students.sibling_id, students.phone2', :joins => "INNER JOIN #{derived_sql_table} finance on finance.student_id=students.id", :group => 'students.id', :include => {:batch => :course}, :order => sort_order)
    additional_details = Student.fetch_additional_details(students)
    data=[]
    col_heads=["#{t('no_text')}", "#{t('name')}", "#{t('admission_no') }", "#{t('course_name')}", "#{t('batch_name')}"]
    (columns["guardian_details"]||[]).each do |details|
      col_heads << t(details)
    end
    (columns["additional_details"]||[]).each do |details|
      col_heads << additional_fields[details.to_sym]
    end
    col_heads += ["#{t('fee_collections')}", "#{t('balance')}(#{ Configuration.find_by_config_key("CurrencyType").config_value})"]
    col_heads.insert(2, t('roll_no')) if Configuration.enabled_roll_number?
    data << col_heads
    total=0
    students.each_with_index do |s, i|
      col=[]
      col<< "#{i+1}"
      col<< "#{s.full_name}"
      col<< "#{s.roll_number}" if Configuration.enabled_roll_number?
      col<< "#{s.admission_no}"
      col<< "#{s.batch.course_name} #{s.batch.code} #{s.batch.section_name}"
      col<< "#{s.batch.name}"
      (columns["guardian_details"]||[]).each do |details|
        col << additional_details[s.id][details.to_sym]
      end
      (columns["additional_details"]||[]).each do |details|
        col << additional_details[s.id][details.to_sym]
      end
      col<< "#{s.fee_collections_count}"
      balance=s.balance
      total+=s.balance.to_f
      col<< "#{precision_label(balance) }"
      col=col.flatten
      data<< col
    end
    data << ["#{t('total_amount')}", "", "", "", "", "", "", total]
    return data
  end

  def self.student_wise_fee_collections(parameters)
    student_id=parameters[:student_id]
    fee_collections = FinanceFeeCollection.all(:select => "finance_fee_collections.name, finance_fee_collections.start_date,
       finance_fee_collections.end_date, finance_fee_collections.due_date, balance",
      :joins => "LEFT OUTER JOIN finance_fees on finance_fees.fee_collection_id=finance_fee_collections.id
                      INNER JOIN students on students.id=finance_fees.student_id
                       LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id",
      :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND students.id=? and finance_fee_collections.is_deleted=? and
       finance_fee_collections.due_date < ? and finance_fees.balance > ?", student_id, false, Date.today, 0.0],
      :order => 'balance DESC')

    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      fee_collections += HostelFeeCollection.all(
        :select => "hostel_fee_collections.name, start_date, end_date, due_date, hostel_fees.balance as balance",
        :joins => "INNER JOIN hostel_fees ON hostel_fees.hostel_fee_collection_id = hostel_fee_collections.id
                    LEFT JOIN fee_accounts fa ON fa.id = hostel_fee_collections.fee_account_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND `hostel_fee_collections`.`is_deleted` = ? AND
          `hostel_fees`.`student_id` = ? and hostel_fees.balance > ? AND hostel_fee_collections.due_date < ? AND
          `hostel_fees`.`is_active` = ?", false, student_id, 0.0, Date.today, true
        ], :order => "balance DESC"
      )
    end

    if FedenaPlugin.can_access_plugin?("fedena_transport")
      fee_collections += TransportFeeCollection.all(
        :select => "transport_fee_collections.id,transport_fee_collections.name, start_date, end_date, due_date,
                    transport_fees.balance as balance",
        :joins => "INNER JOIN transport_fees on transport_fees.transport_fee_collection_id = transport_fee_collections.id
                    LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id",
        :conditions => ["(fa.id IS NULL OR fa.is_deleted = false) AND transport_fee_collections.is_deleted = ? AND
                         `transport_fees`.`receiver_id` = ? AND `transport_fees`.`receiver_type` = 'Student' and
                         transport_fees.balance > ? AND transport_fee_collections.due_date < ? AND
                         `transport_fees`.`is_active` = ?", false, student_id, 0.0, Date.today, true],
        :order => "balance DESC")
    end

    data = []
    col_heads = ["#{t('no_text')}", "#{t('name')}", "#{t('start_date')}", "#{t('due_date')}",
      "#{t('balance')}(#{Configuration.find_by_config_key("CurrencyType").config_value})"]
    data << col_heads
    fee_collections.each_with_index do |b, i|
      col=[]
      col<< "#{i+1}"
      col<< "#{b.name}"
      col<< "#{format_date(b.start_date.to_date)}"
      #      col<< "#{format_date(b.end_date.to_date)}"
      col<< "#{format_date(b.due_date.to_date)}"
      col<< "#{b.balance.nil? ? 0 : b.balance}"
      col=col.flatten
      data<< col
    end
    return data
  end


  def self.fetch_student_advance_search_result(params)
    student_advanced_search params
  end

  def previous_batch
    batch_students.sort_by { |s| s.updated_at||50.years.ago }.last
  end

  def subject_exam(sub_id)
    exam_scores.select { |e| e.try(:exam).try(:subject_id) == sub_id }.empty?
  end
  
  def has_assessment_marks(sub_id)
    assessment_marks.select{|a| a.assessment.try(:subject_id) == sub_id unless a.assessment.class.to_s == 'ActivityAssessment'}.empty?
  end

  def revert_batch_transfer_eligiblity
    warning_messages=[]
    warning_messages << "#{t('elective_subjects_are_assigned')}" unless students_subjects.select { |s| s.try(:batch_id) == batch_id }.empty?
    warning_messages << "#{t('fees_are_already_assigned')}" unless finance_fees.select { |f| f.try(:batch_id) == batch_id }.empty?
    warning_messages << "#{t('already_appeared_for_exam')}" unless exam_scores.select { |e| e.try(:exam).try(:exam_group).try(:batch_id) == batch_id }.empty?
    warning_messages << "#{t('attendance_are_already_marked')}" unless subject_leaves.select { |s| s.try(:batch_id) == batch_id }.empty? and attendances.select { |a| a.try(:batch_id) == batch_id }.empty?
    marks_present   = assessment_marks.select{|a| a.assessment.try(:assessment_group_batch).try(:batch_id) == batch_id }.present? 
    reports_present = individual_reports.select{|r| r.generated_report_batch.try(:batch_id) == batch_id}.present?
    warning_messages << "#{t('mark_entries_in_gradebook')}" if marks_present
    warning_messages << "#{t('report_generated_in_gradebook')}" if marks_present and reports_present
    unless self.previous_batch.nil?
      warning_messages << "#{t('previous_batch_not_present')}" if self.previous_batch.batch.is_deleted
    end
    warning_messages << "#{t('hostel_fees_are_already_assigned')}" if FedenaPlugin.can_access_plugin?('fedena_hostel') and (self.hostel_fees.count(:all,:conditions=>{:batch_id=>self.batch_id, :is_active=>true}) > 0)
    warning_messages << "#{t('transport_fees_are_already_assigned')}" if FedenaPlugin.can_access_plugin?('fedena_transport') and (self.transport_fees.count(:all,:conditions=>{:groupable_id=>self.batch_id, :groupable_type=>'Batch', :is_active=>true}) > 0)

    DependencyHook.check_dependency_for(self, :only => [:assigned_assignments, :online_batch_exams, :batch_poll_votes]).each do |dependency|
      warning_messages << dependency.warning unless dependency.result
    end
    return warning_messages
  end
  
  def reset_gradebook_reports
    self.individual_reports.all(:joins => :generated_report_batch, :conditions => {:generated_report_batches => {:batch_id => self.batch_id}} ).each{|ir| ir.destroy}
    #    self.individual_reports.destroy_all
  end

  def full_name_with_admission_no
    "#{full_name} &#x200E;(#{admission_no})&#x200E;"
  end

  def full_name_with_roll_no
    "#{full_name} &#x200E;- #{roll_number}&#x200E;"
  end

  def name_for_particular_wise_discount
    " &#x200E;(#{full_name})&#x200E;"
  end

  def batch_update
    self.has_paid_fees_for_batch=0
  end

  def is_batch_transfer?
    # TODO use unless defined?(@is_batch_transfer) && @is_batch_transfer == true
    if student_dependencies_list.present? && @is_batch_transfer.nil?
      errors.add_to_base(:batch_can_not_be_modified)
      return false
    end
  end

  def transfer_to_batch(batch,batch_id,attendance_check)
    
    batch_student=self.batch_students.find_by_batch_id(self.batch.id)
    if batch_student.nil?
      self.batch_students.create(:batch_id => self.batch.id, :roll_number => self.roll_number)
    else
      batch_student.touch
    end
    self.update_attributes(:batch_id => batch_id, :is_batch_transfer => true, :roll_number => nil)
    if attendance_check.present?
      attendance_check.map!{|x| x.to_i}
      if attendance_check.include?(self.id)
        new_batch=Batch.find_by_id(batch_id)
        student_attendance=Attendance.find(:all, :conditions =>{:student_id=>self.id,:batch_id=>batch.id,:month_date => new_batch.start_date..new_batch.end_date})
        student_attendance.each do |p|
          p.update_attributes(:batch_id => batch_id)
        end
      end
    end
  end

  def fees_list(batch_id=nil)
    batch_id ||=self.batch_id
    FinanceFeeCollection.find(:all,
      :joins => "INNER JOIN fee_collection_batches on fee_collection_batches.finance_fee_collection_id = finance_fee_collections.id
              INNER JOIN finance_fees on finance_fees.fee_collection_id = finance_fee_collections.id
              INNER JOIN batch_students on batch_students.student_id = #{self.id}
              INNER JOIN batches on (batches.id = batch_students.batch_id or batches.id= #{batch_id})
              INNER JOIN collection_particulars on collection_particulars.finance_fee_collection_id=finance_fee_collections.id
              INNER JOIN finance_fee_particulars on finance_fee_particulars.id=collection_particulars.finance_fee_particular_id and ((finance_fee_particulars.receiver_type='Student' and finance_fee_particulars.receiver_id=finance_fees.student_id) or (finance_fee_particulars.receiver_type='StudentCategory' and finance_fee_particulars.receiver_id=finance_fees.student_category_id) or (finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id=finance_fees.batch_id))",
      :conditions => "finance_fees.student_id='#{self.id}'  and
                    finance_fee_collections.is_deleted=#{false} and
                    (finance_fees.batch_id=batch_students.batch_id or finance_fees.batch_id=#{batch_id})",
      :select => "finance_fee_collections.*,
                batches.name as batch_name",
      :group => "finance_fees.id"
    )
  end

  def get_auto_fine_for_collections(batch_id=nil)
    batch_id ||=self.batch_id
    collection={}
    fees_list(batch_id).each_with_index do |fee_collection,i|
      collection[i]={:name=>fee_collection.name,:fine_amount=>fee_collection.fine_to_pay(self).to_f}
    end
    collection[:total_fine]=collection.inject(0){|s,w| s=s+w[1][:fine_amount].to_f}
    return collection
  end

  def fees_list_by_batch(batch_id=self.batch_id, order=nil, date=nil)
    batch=Batch.find(batch_id)
    unless order.present?
      order = "finance_fees.balance DESC"
    end
    trans_date = date.present? ? date : Date.today
    FinanceFeeCollection.find(:all,
      :joins => " LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
                 INNER JOIN finance_fees  ON finance_fees.fee_collection_id = finance_fee_collections.id                 
                  LEFT JOIN finance_transactions 
                         ON finance_transactions.finance_id = finance_fees.id AND finance_transactions.finance_type ='FinanceFee'
                 INNER JOIN batches ON  batches.id = #{batch_id}",
      :conditions => "(fa.id IS NULL OR fa.is_deleted = false) AND
                    finance_fees.student_id='#{self.id}' and
                    finance_fee_collections.is_deleted = #{false} and
                    finance_fees.batch_id = #{batch_id}",
      :select => "finance_fee_collections.* ,batches.name AS batch_name, finance_fees.is_paid,
                  finance_fees.balance, finance_fees.batch_id, finance_fees.balance_fine AS balance_fine, finance_fees.is_fine_waiver AS is_fine_waiver,
                  MAX(finance_transactions.transaction_date) AS last_transaction_date,
                  SUM(finance_transactions.amount) AS paid_amount,
                  (SELECT IFNULL(SUM(IF(finance_transactions.description = 'fine_amount_included',
                                        finance_transactions.fine_amount, 
                                0)),0)
                     FROM finance_transactions finance_transactions
                    WHERE finance_transactions.finance_id=finance_fees.id AND 
                          finance_transactions.finance_type='FinanceFee'
                  ) AS automatic_fine_paid,
                  (IFNULL((finance_fees.particular_total - finance_fees.discount_amount),
                               finance_fees.balance + 
                               (SELECT IFNULL(SUM(finance_transactions.amount - 
                                                  finance_transactions.fine_amount),
                                             0)
                                  FROM finance_transactions
                                 WHERE finance_transactions.finance_id=finance_fees.id AND 
                                       finance_transactions.finance_type='FinanceFee'
                               ) - 
                               IF(finance_fees.tax_enabled,finance_fees.tax_amount,0)
                               ) 
                              ) AS actual_amount,
                 (SELECT is_amount   FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{trans_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS is_amount,
                 (SELECT fine_amount FROM fine_rules ffr WHERE ffr.fine_id = finance_fee_collections.fine_id AND   
                    ffr.created_at <= finance_fee_collections.created_at AND   ffr.fine_days <= DATEDIFF(   COALESCE(Date('#{trans_date}'),CURDATE()),  
                    finance_fee_collections.due_date )   ORDER BY ffr.fine_days DESC LIMIT 1) AS fine_amount",
      :group => "finance_fees.id",
      :order => order
    )
  end

  def fetch_fees fee_type, batch_id
    tbl_name = fee_type.underscore.pluralize
    inc_assoc = "#{fee_type.underscore}_collection"
    conditions = []
    conditions << "#{tbl_name}.is_active = true" unless fee_type == 'FinanceFee'
    if fee_type == 'TransportFee'
      conditions << "receiver_id = #{self.id}"
      conditions << "receiver_type = 'Student'"
      conditions << "groupable_id = #{batch_id}"
      conditions << "groupable_type = 'Batch'"
    else
      conditions << "#{tbl_name}.student_id = #{self.id}"
      conditions << "#{tbl_name}.batch_id = #{batch_id}"      
    end
    
    # fee_joins = "INNER JOIN finance_fee_collections ffc
    #                      ON ffc.id = #{tbl_name}.fee_collection_id
    #              INNER JOIN collection_particulars cp
    #                      ON cp.finance_fee_collection_id = ffc.id
    #              INNER JOIN finance_fee_particulars ffp
    #                      ON ffp.id = cp.finance_fee_particular_id "

    fee_joins = (
      case fee_type
      when 'FinanceFee'
        " INNER JOIN finance_fee_collections ffc ON ffc.id = #{tbl_name}.fee_collection_id
          INNER JOIN collection_particulars cp ON cp.finance_fee_collection_id = ffc.id
          INNER JOIN finance_fee_particulars ffp ON ffp.id = cp.finance_fee_particular_id"
      when 'TransportFee'
        " INNER JOIN transport_fee_collections ffc ON ffc.id = #{tbl_name}.transport_fee_collection_id"
      when 'HostelFee'
        " INNER JOIN hostel_fee_collections ffc ON ffc.id = #{tbl_name}.hostel_fee_collection_id"
      else
        " "
      end)
    fee_joins += " LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id" if fee_joins.present?

    fees_where = fee_type == 'FinanceFee' ? " AND
                  ffc.is_deleted = false AND
                  ((ffp.receiver_type='Batch' and ffp.receiver_id=#{tbl_name}.batch_id) or
                   (ffp.receiver_type='Student' and ffp.receiver_id=#{tbl_name}.student_id) or
                   (ffp.receiver_type='StudentCategory' and ffp.receiver_id=#{tbl_name}.student_category_id)
                  )" : ""

    if fee_joins.present?
      fees_where += " AND " #if fee_type == 'FinanceFee'
      fees_where += " (ffc.fee_account_id IS NULL OR (ffc.fee_account_id IS NOT NULL AND fa.is_deleted = false))"
    end
    # fees_where = fee_type == 'FinanceFee' ? " AND
    #               ffc.is_deleted = false AND
    #               ((ffp.receiver_type='Batch' and ffp.receiver_id=#{tbl_name}.batch_id) or
    #                (ffp.receiver_type='Student' and ffp.receiver_id=#{tbl_name}.student_id) or
    #                (ffp.receiver_type='StudentCategory' and ffp.receiver_id=#{tbl_name}.student_category_id)
    #               )" : ""
    trans_select = "(SELECT SUM(ft.amount) FROM finance_transactions ft 
                      WHERE ft.finance_id=#{tbl_name}.id AND ft.finance_type='#{fee_type}' AND
                            FIND_IN_SET(ft.finance_id,GROUP_CONCAT(distinct #{tbl_name}.id))
                    ) AS paid_amount"
    trans_joins = " LEFT JOIN finance_transactions ft ON ft.finance_id = #{tbl_name}.id AND ft.finance_type ='#{fee_type}'"
    fee_name = (fee_type.constantize rescue nil) 
    conditions = conditions.compact.join(" AND ")
    conditions += fees_where #if fee_type == 'FinanceFee'
    joins = "#{fee_joins} #{trans_joins}"
    fee_name.present? ? (fee_name.all(:conditions => conditions, 
        :include => "#{inc_assoc}", :joins => joins, :group => "#{tbl_name}.id",
        :select => "#{tbl_name}.*, #{trans_select}, MAX(ft.transaction_date) AS last_transaction_date")) : []
  end
  
  def self.fetch_student_fees_structure_data params
    student_fees_structure_data(params)
  end
  
  def self.fetch_students_structure_data params    
    students = fetch_students_structure(params)
    fee_structure_overview_data(params.merge({:students => students}))
  end
  
  def self.fetch_students_structure(args={})
    batch_id = args[:batch_id]
    query = args[:query]
    result_type = args[:query].length>= 3 ? 'query_2' : 'query_1' if args[:query].present?
    result_type = 'batch' if args[:batch_id].present?    
    
    students = []
    precision_count = FedenaPrecision.get_precision_count    
    case result_type
    when 'batch'
      students = Student.find(:all,
        :select => "students.id AS id, IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           students.batch_id AS batch_id,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           students.admission_no AS admission_no,
                           (SELECT SUM(ff.balance) 
                               FROM finance_fees ff
                               INNER JOIN finance_fee_collections ffc ON ffc.id = ff.fee_collection_id
                                LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id
                             WHERE  ff.student_id=students.id AND ff.batch_id = #{batch_id} AND
                                          FIND_IN_SET(ff.id,GROUP_CONCAT(DISTINCT finance_fees.id)) AND
                                    (fa.id IS NULL OR fa.is_deleted = false)
                            ) AS fee_due,
                           (SELECT COUNT(DISTINCT ff.id) 
                               FROM finance_fees ff 
                         INNER JOIN finance_fee_collections ffc 
			                           ON ffc.id = ff.fee_collection_id
                          LEFT JOIN fee_accounts fa ON fa.id = ffc.fee_account_id
	                       INNER JOIN collection_particulars cp
			                           ON cp.finance_fee_collection_id = ffc.id
	                       INNER JOIN finance_fee_particulars ffp
			                           ON ffp.id = cp.finance_fee_particular_id
                             WHERE  ff.student_id=students.id AND 
                                    ff.batch_id = #{batch_id} AND
                                    (fa.id IS NULL OR fa.is_deleted = false) AND
                                    FIND_IN_SET(ff.id,GROUP_CONCAT(DISTINCT finance_fees.id)) AND		       
                                    ffc.is_deleted=false AND 
                                    ((ffp.receiver_type='Batch' AND ffp.receiver_id=ff.batch_id) OR 
                                     (ffp.receiver_type='Student' AND ffp.receiver_id=ff.student_id) OR 
                                     (ffp.receiver_type='StudentCategory' AND ffp.receiver_id=ff.student_category_id))
                            ) AS fee_count, students.roll_number,
                            #{fine_amount_for_fees(batch_id)} AS fine_amount, 
                            #{transport_fee_due(batch_id)} AS transport_due,
                            #{transport_fee_count(batch_id)} AS transport_count,
                            #{hostel_fee_due(batch_id)} AS hostel_due, 
                            #{hostel_fee_count(batch_id)} AS hostel_count",
        :joins => join_sql_for_student_fees(batch_id),
        :group => "students.id", #:having => having, 
        :conditions => ["students.batch_id = ? #{account_deletion_conditions}", batch_id],
        :order => "batches.id asc,students.first_name asc"
      )
    when 'query_1' # query length greater than or equal to 3
      students = Student.find(:all,
        :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           students.batch_id AS batch_id,
                           IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ROUND(ff.balance,#{precision_count})) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(DISTINCT finance_fees.id))) AS fee_due,
                           (SELECT COUNT(ff.id) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            ff.batch_id = students.batch_id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_count,
                            #{fine_amount_for_fees} AS fine_amount,
                            #{transport_fee_due} AS transport_due, 
                            #{transport_fee_count} AS transport_count, 
                            #{hostel_fee_due} AS hostel_due,
                            #{hostel_fee_count} AS hostel_count",
        :joins => join_sql_for_student_fees("current_batch"), :group => "students.id", 
        :conditions => ["admission_no = ? #{account_deletion_conditions}", query],
        :order => "batches.id ASC, students.first_name ASC")
    when 'query_2' # query length greater than or equal to 3
      students = Student.find(:all,
        :select => "students.id AS id, students.admission_no AS admission_no, students.roll_number,
                           students.batch_id AS batch_id,
                           IF(CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name) is NULL,
                           CONCAT(students.first_name,' ',  students.last_name), CONCAT(students.first_name,' ',students.middle_name,' ',  students.last_name)) AS fullname,
                           CONCAT(courses.code,'-',batches.name) AS batch_full_name,
                           (SELECT SUM(ROUND(ff.balance,#{precision_count})) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            FIND_IN_SET(id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_due,
                           (SELECT COUNT(ff.id) FROM finance_fees ff WHERE  ff.student_id=students.id AND 
                            ff.batch_id = students.batch_id AND 
                            FIND_IN_SET(ff.id,GROUP_CONCAT(distinct finance_fees.id))) AS fee_count,
                            #{fine_amount_for_fees} AS fine_amount,
                            #{transport_fee_due} AS transport_due, 
                            #{transport_fee_count} AS transport_count, 
                            #{hostel_fee_due} AS hostel_due,
                            #{hostel_fee_count} AS hostel_count",
        :joins => join_sql_for_student_fees("current_batch"), :group => "students.id",
        :conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ? OR
                          admission_no = ? OR
                          (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ) OR
                          (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                          #{account_deletion_conditions}", "#{query}%", "#{query}%", "#{query}%", "#{query}",
          "#{query}%", "#{query}%"],
        :order => "batches.id ASC, students.first_name ASC")    
    end  
    students
  end
  
  def self.fine_amount_for_fees batch_id=nil
    batch_con = batch_id.present? ? "ff.batch_id=#{batch_id} and" : ""
    balance_fine_con = Configuration.is_fine_settings_enabled? ? "IF(ff.balance_fine IS NOT NULL AND ff.balance = 0.0 AND ff.is_paid = false,ff.balance_fine, " : "("
    "(SELECT SUM(#{balance_fine_con} IF(fine_rules.is_amount,
			  fine_rules.fine_amount,
              ((ff.balance - 
                IF(ff.tax_enabled,
                   IFNULL(ff.tax_amount,0),0) + (SELECT IFNULL(SUM(finance_transactions.amount - 
																			 IF(ff.tax_enabled,
																				finance_transactions.tax_amount,0) - 
																			 finance_transactions.fine_amount),0) 
														   FROM finance_transactions
														  WHERE finance_transactions.finance_id = ff.id AND 
																finance_transactions.finance_type='FinanceFee') 
				) * fine_rules.fine_amount / 100
			  )	
             ) - 
 (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
 FROM finance_transactions 
 WHERE finance_transactions.finance_id = ff.id AND 
 finance_transactions.finance_type = 'FinanceFee' AND 
 description= 'fine_amount_included')
 ))
		
		
		
		  FROM `finance_fees` ff 
		 INNER JOIN `finance_fee_collections` ON `finance_fee_collections`.id = ff.fee_collection_id
		  LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
		 INNER JOIN `fines` ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false
		 LEFT JOIN `fine_rules` ON fine_rules.fine_id = fines.id AND fine_rules.id= (SELECT ffr.id
																					 FROM fine_rules ffr 
																					WHERE ffr.fine_id=fines.id AND 
																						  ffr.created_at <= finance_fee_collections.created_at AND 
																						  ffr.fine_days <= DATEDIFF(COALESCE(Date('#{Date.today}'), CURDATE()),
																													finance_fee_collections.due_date)
																					ORDER BY ffr.fine_days DESC LIMIT 1)
         WHERE (fa.id IS NULL OR fa.is_deleted = false) AND (#{batch_con} ff.is_paid=false) AND FIND_IN_SET(ff.id,GROUP_CONCAT(DISTINCT finance_fees.id))
	     )" 
  end
  
  def self.transport_fee_count batch_id=nil
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      batch_id_join = batch_id.present? ? "tf.groupable_type='Batch' AND 
                                           tf.groupable_id=#{batch_id} AND " : 
        "students.batch_id AND "
      "(SELECT COUNT(DISTINCT tf.id) 
          FROM transport_fees tf
    INNER JOIN transport_fee_collections tfc1 ON tfc1.id = tf.transport_fee_collection_id
     LEFT JOIN fee_accounts fa1 ON fa1.id = tfc1.fee_account_id
         WHERE tf.receiver_id=students.id AND tf.receiver_type='Student' AND
               (tfc1.fee_account_id IS NULL OR
                (tfc1.fee_account_id IS NOT NULL AND fa1.is_deleted = false)) AND
               #{batch_id_join}
               FIND_IN_SET(tf.id,GROUP_CONCAT(DISTINCT transport_fees.id)))"
    else
      0
    end    
  end
  
  def self.hostel_fee_count batch_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      batch_id_join = batch_id.present? ? "hf.batch_id = #{batch_id} AND " : 
        "students.batch_id AND "
      "(SELECT COUNT(DISTINCT hf.id) 
          FROM hostel_fees hf
    INNER JOIN hostel_fee_collections hfc1 ON hfc1.id = hf.hostel_fee_collection_id
     LEFT JOIN fee_accounts fa1 ON fa1.id = hfc1.fee_account_id
         WHERE hf.student_id=students.id AND
               (hfc1.fee_account_id IS NULL OR fa1.is_deleted = false) AND
               #{batch_id_join}
               FIND_IN_SET(hf.id,GROUP_CONCAT(DISTINCT hostel_fees.id)))"
    else
      0
    end    
  end
  
  def self.transport_fee_due batch_id = nil
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      batch_id_join = batch_id.present? ? "tf.groupable_type='Batch' AND 
                                           tf.groupable_id=#{batch_id} AND " : ""
      #      "(SELECT SUM(tf.balance) 
      "(SELECT SUM(ROUND(tf.balance,#{FedenaPrecision.get_precision_count}))
           FROM transport_fees tf
           INNER JOIN transport_fee_collections tfc1 ON tfc1.id = tf.transport_fee_collection_id
           LEFT JOIN fee_accounts fa1 ON fa1.id = tfc1.fee_account_id
        WHERE tf.receiver_id=students.id AND tf.receiver_type='Student' AND
              (tfc1.fee_account_id IS NULL OR
               (tfc1.fee_account_id IS NOT NULL AND fa1.is_deleted = false)) AND
              #{batch_id_join}
              FIND_IN_SET(tf.id,GROUP_CONCAT(DISTINCT transport_fees.id))
       )"
    else
      0
    end
  end
  
  def self.hostel_fee_due batch_id=nil
    if FedenaPlugin.can_access_plugin?("fedena_hostel")
      batch_id_join = batch_id.present? ? "hf.batch_id = #{batch_id} AND " : ""
      #      "(SELECT SUM(hf.balance) 
      "(SELECT SUM(ROUND(hf.balance,#{FedenaPrecision.get_precision_count}))
          FROM hostel_fees hf
    INNER JOIN hostel_fee_collections hfc1 ON hfc1.id = hf.hostel_fee_collection_id
     LEFT JOIN fee_accounts fa1 ON fa1.id = hfc1.fee_account_id
         WHERE hf.student_id = students.id AND
               (hfc1.fee_account_id IS NULL OR fa1.is_deleted = false) AND
               #{batch_id_join}
               FIND_IN_SET(hf.id,GROUP_CONCAT(DISTINCT hostel_fees.id)))"
    else
      0
    end    
  end

  def self.account_deletion_conditions conjugate = true
    ## TO DO: check if OR condition works well or AND should be used for various types of fees like ff / hf / tf
    cond = conjugate ? " AND (" : "("
    cond += "(ffc.fee_account_id IS NULL OR (ffc.fee_account_id IS NOT NULL AND fa_ff.is_deleted = false))"
    cond += " OR (tfc.fee_account_id IS NULL OR (tfc.fee_account_id IS NOT NULL AND fa_tf.is_deleted = false))" if FedenaPlugin.can_access_plugin?("fedena_transport")
    cond += " OR (hfc.fee_account_id IS NULL OR (hfc.fee_account_id IS NOT NULL AND fa_hf.is_deleted = false))" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    cond += ")"
  end

  def self.join_sql_for_student_fees(batch_id=nil)
    if batch_id.present?
      join_batch_id = (batch_id == "current_batch") ? "students.batch_id" : "#{batch_id}"
      transport_sql = "AND transport_fees.groupable_id=#{join_batch_id}"
      hostel_sql = "AND hostel_fees.batch_id=#{join_batch_id}"
      finance_sql = "AND finance_fees.batch_id=#{join_batch_id}"
    else
      transport_sql = hostel_sql = finance_sql = ""
    end

    result  = "INNER JOIN batches ON batches.id=students.batch_id 
               INNER JOIN courses ON courses.id=batches.course_id
                LEFT JOIN finance_fees
                       ON finance_fees.student_id=students.id #{finance_sql}
                LEFT JOIN finance_fee_collections ffc ON ffc.id = finance_fees.fee_collection_id
                LEFT JOIN fee_accounts fa_ff ON fa_ff.id = ffc.fee_account_id"
    result +=" LEFT JOIN transport_fees 
                      ON transport_fees.receiver_id=students.id AND
                         transport_fees.receiver_type='Student' AND
                         transport_fees.is_active=1 #{transport_sql}
               LEFT JOIN transport_fee_collections tfc ON tfc.id = transport_fees.transport_fee_collection_id
               LEFT JOIN fee_accounts fa_tf ON fa_tf.id = tfc.fee_account_id" if FedenaPlugin.can_access_plugin?("fedena_transport")
    result +=" LEFT JOIN hostel_fees 
                      ON hostel_fees.student_id=students.id AND
                         hostel_fees.is_active=1 #{hostel_sql}
               LEFT JOIN hostel_fee_collections hfc ON hfc.id = hostel_fees.hostel_fee_collection_id
               LEFT JOIN fee_accounts fa_hf ON fa_hf.id = hfc.fee_account_id" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    result    
  end
  
  def self.fetch_student_fees_data(params)
    student_fees_data params
  end

  def self.search_by_admission_no_or_name(search_string)
    search_string.strip!
    scoped(:conditions => ["ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                   OR admission_no = ? OR (concat(trim(first_name), \" \",trim(last_name)) LIKE ? )
                   OR (concat(trim(first_name), \" \", trim(middle_name), \" \",trim(last_name)) LIKE ? ) ",
        "#{search_string}%", "#{search_string}%", "#{search_string}%",
        "#{search_string}", "#{search_string}%", "#{search_string}%"])
  end

  def has_pending_finance_fees?
    FinanceFee.find(:all, :joins => [:student], :conditions => {:students => {:id => self.id}, :finance_fees => {:is_paid => false}}).present?
  end

  def has_pending_fees?
    result=has_pending_finance_fees?
    # TODO replace this with plugin hooks
    result = result || has_pending_hostel_fees? if FedenaPlugin.can_access_plugin?("fedena_hostel")
    result = result || has_pending_transport_fees? if FedenaPlugin.can_access_plugin?("fedena_transport")
    return result
  end

  def self.students_with_pending_finance_fees
    # Student.all.collect{|student| student.finance_fees}.flatten.collect{|s| s.is_paid}
    Student.find(:all, :joins => [:finance_fees], :conditions => {:finance_fees => {:is_paid => false}})
  end

  def self.students_with_pending_fees
    result=self.students_with_pending_finance_fees
    # TODO add plugins conditions here
  end

  def valid?
    super && self.user.valid?
  end


  def is_in_active_batch?
    self.errors.add_to_base(t('selected_batch_is_not_active')) unless Batch.find(self.batch_id).is_active==true
  end

  def has_remarks_privilege
    current_user = Authorization.current_user
    if current_user.student?
      return current_user.student_entry.id == id
    elsif current_user.parent?
      return current_user.guardian_entry.wards.collect(&:id).include? id
    end
  end

  def paid_manual_fine(batch_id=nil)
    fee_types = ["'FinanceFee'"]
    fee_types << "'HostelFee'" if FedenaPlugin.can_access_plugin?("fedena_hostel")
    fee_types << "'TransportFee'" if FedenaPlugin.can_access_plugin?("fedena_transport")
    conditions = "fine_included = true AND "
    conditions += batch_id.present? ? "(batch_id IS NULL OR batch_id=#{batch_id}) AND " : ""
    conditions += "finance_type in (#{fee_types.join(',')})"
    finance_transactions.all(:conditions => conditions, 
      :select => "SUM(IFNULL(IF(description = 'fine_amount_included', 
                                               IF(auto_fine > 0, fine_amount - auto_fine, 0),
                                               fine_amount),0)) AS paid_manual_fine", 
      :group => "payee_id").map {|x| x.paid_manual_fine.to_f }.sum
  end
  
  def total_automatic_finance_fee_fine(batch_id=nil,finance_fees_ids=nil)
    joins="INNER JOIN `finance_fee_collections` 
                   ON `finance_fee_collections`.id = `finance_fees`.fee_collection_id
            LEFT JOIN fee_accounts fa ON fa.id = finance_fee_collections.fee_account_id
              INNER JOIN `fines` 
                           ON `fines`.id = `finance_fee_collections`.fine_id AND fines.is_deleted is false
                 LEFT JOIN `fine_rules` 
                           ON `fine_rules`.fine_id = fines.id  AND 
                                 `fine_rules`.id= (SELECT id 
                                                             FROM fine_rules ffr 
                                                          WHERE ffr.fine_id=fines.id AND 
                                                                      ffr.created_at <= finance_fee_collections.created_at AND 
                                                                      ffr.fine_days <= DATEDIFF(COALESCE(
                                                                                                  Date('#{Date.today}'), CURDATE()),
                                                                                                  finance_fee_collections.due_date)
                                                      ORDER BY ffr.fine_days DESC LIMIT 1)"
    conditions = "(fa.id IS NULL OR fa.is_deleted = false) AND "
    conditions += batch_id.present? ? "finance_fees.batch_id=#{batch_id} and
                                      finance_fees.is_paid=false" : 
      "finance_fees.is_paid=false"
    
    if finance_fees_ids.present?
      conditions<< " and finance_fees.id in (?) "
      conditions=conditions.to_a << finance_fees_ids
    end
    balance_fine_cond = Configuration.is_fine_settings_enabled? ? "IF(finance_fees.balance_fine IS NOT NULL AND finance_fees.balance = 0.0 AND finance_fees.is_paid = false,finance_fees.balance_fine, " : "("
    waiver_cond = "IF(finance_fees.is_fine_waiver = true, 0.0, #{balance_fine_cond}"
    fine_amount_to_pay = finance_fees.all(:joins => joins,
      :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount, fine_rules.fine_amount,
                         ((finance_fees.balance - 
                           IF(finance_fees.tax_enabled,IFNULL(finance_fees.tax_amount,0),0) + 
                              (SELECT IFNULL(SUM(finance_transactions.amount - 
                                             IF(finance_fees.tax_enabled,
                                                finance_transactions.tax_amount,0) - 
                                                finance_transactions.fine_amount),0) 
                                 FROM finance_transactions
                                WHERE finance_transactions.finance_id = finance_fees.id AND 
                                      finance_transactions.finance_type='FinanceFee') 
                              ) * fine_rules.fine_amount / 100
                          )
                         ) - 
                         (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                            FROM finance_transactions  
                           WHERE finance_transactions.finance_id = finance_fees.id AND 
                                 finance_transactions.finance_type = 'FinanceFee' AND 
                                 description= 'fine_amount_included')
                         ))) AS fine_amount",      
      :conditions => conditions,
      :group => "finance_fees.student_id").first.try(:fine_amount).to_f
    if FedenaPlugin.can_access_plugin?("fedena_transport")
      transport_fine_cond = balance_fine_cond.gsub('finance_fees','transport_fees')
      joins="INNER JOIN `transport_fee_collections` 
                     ON `transport_fee_collections`.id = `transport_fees`.transport_fee_collection_id
              LEFT JOIN fee_accounts fa ON fa.id = transport_fee_collections.fee_account_id
             INNER JOIN `fines` ON `fines`.id = `transport_fee_collections`.fine_id AND fines.is_deleted is false
              LEFT JOIN `fine_rules`
                     ON `fine_rules`.fine_id = fines.id  AND
                         `fine_rules`.id= (SELECT id
                                             FROM fine_rules ffr
                                            WHERE ffr.fine_id=fines.id AND
                                                  ffr.created_at <= transport_fee_collections.created_at AND
                                                  ffr.fine_days <= DATEDIFF(COALESCE(
                                                                             Date('#{Date.today}'), CURDATE()),
                                                                             transport_fee_collections.due_date)
                                         ORDER BY ffr.fine_days DESC LIMIT 1)"
      conditions = batch_id.present? ? "transport_fees.groupable_id=#{batch_id} and 
                                        transport_fees.groupable_type='Batch' and 
                                        transport_fees.is_active=true and
                                        transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false) " :
        "transport_fees.is_paid <> true AND (fa.id IS NULL OR fa.is_deleted = false)"
      #      if finance_fees_ids.present?
      #        conditions<< " and transport_fees.id in (?)"
      #        conditions=conditions.to_a << finance_fees_ids
      #      end
      waiver_cond = "IF(transport_fees.is_fine_waiver = true, 0.0, #{transport_fine_cond}"
      fine_amount_to_pay += transport_fees.all(:joins => joins,
        :select => "SUM(#{waiver_cond} IF(fine_rules.is_amount,
                           fine_rules.fine_amount,
                           ((transport_fees.balance - 
                             IF(transport_fees.tax_enabled,IFNULL(transport_fees.tax_amount,0),0) + 
                                (SELECT IFNULL(SUM(finance_transactions.amount - 
                                         IF(transport_fees.tax_enabled,
                                            finance_transactions.tax_amount,0) - 
                                            finance_transactions.fine_amount),0) 
                                   FROM finance_transactions
                                  WHERE finance_transactions.finance_id = transport_fees.id AND 
                                        finance_transactions.finance_type='TransportFee') 
                               ) * fine_rules.fine_amount / 100
                             )
                           ) - 
                           (SELECT IFNULL(SUM(finance_transactions.fine_amount),0) 
                              FROM finance_transactions  
                             WHERE finance_transactions.finance_id = transport_fees.id AND 
                                   finance_transactions.finance_type = 'TransportFee' AND 
                                   description= 'fine_amount_included')
                       ))) AS tf_fine_amount",      
        :conditions => conditions,
        :group => "transport_fees.receiver_id").map {|x| x.tf_fine_amount.to_f }.sum
    end    
    fine_amount_to_pay
  end
  
  def original_fee_collection_batch(collection_id,type)
    if type=="finance"
      finance_fees.first(:conditions=>{:fee_collection_id=>collection_id}).batch
    elsif type=="transport"
      transport_fees.first(:conditions=>{:transport_fee_collection_id=>collection_id, :groupable_type=>"Batch"}).groupable
    elsif type=="hostel"
      hostel_fees.first(:conditions=>{:hostel_fee_collection_id=>collection_id}).batch
    end  
  end
  
  def self.csv_siblings_report(parameters)
    
    batch_id= parameters[:batch_id].present? ? parameters[:batch_id]["batch_ids"] : nil
    if parameters[:type].present? and parameters[:type] == "course"
      students=Student.student_with_siblings(parameters[:sort_order]).with_batch(parameters[:batch_id]["batch_ids"])
    else
      students=Student.primary_student_with_siblings(parameters[:sort_order])
    end
    
    data=[]
    if batch_id.present?
      b=Batch.find(batch_id)
      col_class=[]
      col_class << t('course')
      col_class << b.first.course.full_name
      data<<col_class
      
      col_batch = []
      col_batch << t('batches_text')
      add=[]
      b.each do |batch|
        add << batch.full_name
        add<< " \n"
        add = add.flatten
      end
      add=add.first add.size - 1
      col_batch << add
      data<<col_batch
    end
    col_heads=["#{t('no_text')}","#{t('name')}",t('admission_number'), t('batch'), t('sibling_name'), t('sibling_admission_no'), t('sibling_batch'), t('father_name'), t('father_mobile'), t('father_email'), t('mother_name'), t('mother_mobile'), t('mother_email'),t('other_guardians'),t('relation'),t('mobile'),t('email')]
    data << col_heads
    students.each_with_index do |student,index|
      col=[]
      col<< index+1
      col<< student.full_name
      col<< student.admission_no
      col<< student.batch.full_name
      fnames=student.sibling_fname
      fnames=fnames.present? ? fnames.split(',') : ""
      lnames=student.sibling_lname
      lnames=lnames.present? ? lnames.split(',') : ""
      mnames=student.sibling_mname
      mnames=mnames.present? ? mnames.split(',') : ""
      admission_no=student.sibling_admission_nos
      admission_no=admission_no.split(',')
      batch=student.batch_name
      batch=batch.split(',')
      course=student.sibling_course_name
      course=course.split(',')
      
      add = []
      fnames.each_with_index do |n,i|
        add << "#{n} #{mnames[i]} #{lnames[i]}".strip
        add<< " \n"
        add = add.flatten
      end
      add=add.first add.size - 1
      col << add
      
      add=[]
      admission_no.each do |ad_no|
        add << ad_no
        add<< " \n"
        add = add.flatten
      end
      add=add.first add.size - 1
      col << add
      
      add = []
      batch.each_with_index do |b,i|
        add << "#{course[i]} - #{b}"
        add<< " \n"
        add = add.flatten
      end
      add=add.first add.size - 1
      col << add 
      
      father=student.guardians.to_a.find{|x| x.relation =~ /father/}
      col<< "#{father.try(:full_name)|| ""}"
      col<< "#{father.try(:mobile_phone) || ""}"
      col<< "#{father.try(:email) || ""}"
            
      mother=student.guardians.to_a.find{|x| x.relation =~ /mother/}
      col<< "#{mother.try(:full_name) || ""}"
      col<< "#{mother.try(:mobile_phone) || ""}"
      col<< "#{mother.try(:email) || ""}"
      
      other_guardian=student.guardians.to_a.find_all{|x| x.relation !~ /father|mother/}
      if other_guardian.present?
        add = []
        other_guardian.each do |other|
          add << "#{other.first_name} #{other.last_name}"
          add<< " \n"
          add = add.flatten
        end
        add=add.first add.size - 1
        col << add 
        
        add = []
        other_guardian.each do |other|
          add << "#{other.relation}"
          add<< " \n"
          add = add.flatten
        end
        add=add.first add.size - 1
        col << add 
      
        add = []
        other_guardian.each do |other|
          add << "#{other.mobile_phone}"
          add<< " \n"
          add = add.flatten
        end
        add=add.first add.size - 1
        col << add 
        
        add = []
        other_guardian.each do |other|
          add << "#{other.email}"
          add<< " \n"
          add = add.flatten
        end
        add=add.first add.size - 1
        col << add       
      else
        col<<""
        col<<""
        col<<""
        col<<""
      end
      data << col
    end
    return data
  end
  
  def guardian_sms_content(date)
    unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="SubjectWise"
      attendance = Attendance.find_by_student_id_and_month_date(self.id,date)
      if attendance.is_full_day
        guardian_message = "#{t('dear_parent')}, #{self.first_and_last_name} #{t('is_for_attendance')} #{attendance.attendance_label_name} #{t('on_for_attendance')} #{format_date(attendance.month_date)}. #{t('thanks')}"
      elsif attendance.forenoon == true and attendance.afternoon == false
        guardian_message = "#{t('dear_parent')}, #{self.first_and_last_name}  #{t('is_for_attendance')} #{attendance.attendance_label_name} #{t('on_for_attendance')}  #{format_date(attendance.month_date)} #{t('during_forenoon')}. #{t('thanks')}"
      elsif attendance.afternoon == true and attendance.forenoon == false
        guardian_message = "#{t('dear_parent')}, #{self.first_and_last_name}  #{t('is_for_attendance')} #{attendance.attendance_label_name} #{t('on_for_attendance')}  #{format_date(attendance.month_date)} #{t('during_afternoon')}. #{t('thanks')}"
      end
    else
      subject_leaves = SubjectLeave.find_by_student_id_and_month_date_and_subject_id(self.id,date,sub_id)
      guardian_message = "#{t('your_ward')} #{self.first_and_last_name}  #{t('is_for_attendance')} #{attendance.attendance_label_name} #{t('on_for_attendance')} #{format_date(subject_leaves.month_date)} #{t('for_subject')} #{subject_leaves.subject.name} #{t('during_period')} #{subject_leaves.class_timing.try(:name)}. #{t('thanks')}"
    end
    return guardian_message
  end
  
  def student_sms_content(date)
    unless Configuration.find_by_config_key('StudentAttendanceType').config_value=="SubjectWise"
      attendance = Attendance.find_by_student_id_and_month_date(self.id,date)
      if attendance.is_full_day
        student_message = "#{t('hi_you_are_marked')} #{attendance.attendance_label_name} #{t('on_for_attendance')} #{format_date(attendance.month_date)}. #{t('thanks')}"
      elsif attendance.forenoon == true and attendance.afternoon == false
        student_message = "#{t('hi_you_are_marked')} #{attendance.attendance_label_name} #{t('on_for_attendance')} #{format_date(attendance.month_date)} #{t('during_forenoon')}. #{t('thanks')}"
      elsif attendance.afternoon == true and attendance.forenoon == false
        student_message = "#{t('hi_you_are_marked')}#{attendance.attendance_label_name} #{t('on_for_attendance')} #{format_date(attendance.month_date)} #{t('during_afternoon')}. #{t('thanks')}"
      end
    else
      subject_leaves = SubjectLeave.find_by_student_id_and_month_date_and_subject_id(self.id,date,sub_id)
      student_message = "#{t('hi_you_are_marked')} #{attendance.attendance_label_name} #{t('on_for_attendance')}#{format_date(subject_leaves.month_date)} #{t('for_subject')} #{subject_leaves.subject.name} #{t('during_period')} #{subject_leaves.class_timing.try(:name)}. #{t('thanks')}"
    end
    return student_message
  end
  
  def self.fetch_additional_details(students)
    details = UserAdditionalDetails.new(students, 'Student', true)
    details.fetch_additional_details
  end
  
  def name_with_roll_number
    if Configuration.enabled_roll_number?
      self.full_name + "(#{self.roll_number.to_s})"
    else
      self.full_name + "(#{self.admission_no.to_s})"
    end
  end
  
  def check_fee_dues
    finance_fees = self.finance_fees.select{|m| !m.transaction_id.present? and m.is_paid == false} + self.hostel_fees.select{|m| m.is_active && (!m.finance_transaction_id.present? || m.balance != 0)}  +  self.transport_fees.select{|m| m.is_active && (!m.transaction_id.present? || m.balance != 0 || m.balance_fine != 0)}
    return finance_fees.present?
  end
  
end