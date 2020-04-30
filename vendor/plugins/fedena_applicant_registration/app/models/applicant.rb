
class Applicant < ActiveRecord::Base
  require 'set'
  require 'fileutils'


  serialize :subject_ids
  serialize :normal_subject_ids
  serialize :subject_amounts

  has_many :applicant_guardians, :dependent => :destroy
  has_one :applicant_previous_data, :dependent => :destroy
  has_many :applicant_addl_values, :dependent => :destroy
  has_many :applicant_additional_details, :dependent => :destroy
  has_many :applicant_addl_attachments, :dependent => :destroy
  has_one :finance_transaction, :as => :payee

  belongs_to :registration_course
  belongs_to :country
  belongs_to :nationality,:class_name=>"Country"
  belongs_to :batch
  belongs_to :application_status,:foreign_key=>"status"

  #validates_presence_of :first_name,:registration_course_id,:date_of_birth,:gender,:last_name
  validates_presence_of :registration_course_id
  #validates_presence_of :subject_ids,:if => :is_subject_based_and_minimum_electives_is_not_zero

  validates_format_of  :email, :with => /^[\+A-Z0-9\._%-]+@([A-Z0-9-]+\.)+[A-Z]{2,6}$/i,:if=>:check_email, :message => :address_must_be_valid

  before_validation :initialize_children

  before_save :generate_reg_no
  #  before_save :check_course_is_active
  before_create :set_pending_status

  after_create :save_print_token
  after_save :check_guardian_addl_values
  before_save :verify_precision
  after_update :send_notification
  before_save :check_if_attachment_deleted

  def verify_precision
    self.amount = FedenaPrecision.set_and_modify_precision self.amount
  end
  VALID_IMAGE_TYPES = ['image/gif', 'image/png','image/jpeg', 'image/jpg']
  has_attached_file :photo,
    :styles => {:original=> "125x125#"},
    :url => "/uploads/:class/:id/:attachment/:attachment_fullname?:timestamp",
    :path => "uploads/:class/:attachment/:id_partition/:style/:basename.:extension",
    :default_url => "master_student/profile/default_student.png",
    :default_path => ":rails_root/public/images/master_student/profile/default_student.png",
    :reject_if => proc { |attributes| attributes.present? },
    :max_file_size => 512000,
    :permitted_file_types =>VALID_IMAGE_TYPES

  validates_attachment_content_type :photo, :content_type =>VALID_IMAGE_TYPES,
    :message=>'Image can only be GIF, PNG, JPG',:if=> Proc.new { |p| !p.photo_file_name.blank? }
  validates_attachment_size :photo, :less_than => 512000,\
    :message=>'must be less than 500 KB.',:if=> Proc.new { |p| p.photo_file_name_changed? }


  accepts_nested_attributes_for :applicant_addl_attachments, :allow_destroy => true
  accepts_nested_attributes_for :applicant_additional_details, :allow_destroy => true
  accepts_nested_attributes_for :applicant_guardians, :allow_destroy => true
  accepts_nested_attributes_for :applicant_previous_data, :allow_destroy => true
  accepts_nested_attributes_for :applicant_addl_values, :allow_destroy => true


  attr_accessor :addl_field, :m_attr, :m_g_attr, :m_p_attr, :m_add_attr, :m_att_attr, :m_s_add, :hostname, :being_allotted, :delete_attachment, :guardians, :payment_pending

  def is_updating_status
    if !(self.new_record?) and (self.changed.count <= 2 and !((self.changed - ["status","has_paid"]).present?))
      return true
    else
      return false
    end
  end

  def check_if_attachment_deleted
    if self.delete_attachment.present? and self.delete_attachment.to_s == "true"
      unless self.changed.include?("photo_updated_at")
        self.photo.clear
      end
    end
  end


  def is_subject_based_and_minimum_electives_is_not_zero
    unless self.is_updating_status
      self.registration_course.is_subject_based_registration.to_s == "true" and self.registration_course.min_electives!=0
    end
  end

  def total_amount
    registration_course = self.registration_course
    if @registration_course.is_subject_based_registration
      subject_amounts = registration_course.course.subject_amounts
      ele_subject_amount = subject_amounts.find(:all,:conditions => {:code => self.subject_ids}).flatten.compact.map(&:amount).sum
      if registration_course.subject_based_fee_colletion
        normal_subjects=registration_course.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
        normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => normal_subjects}).flatten.compact.map(&:amount).sum.to_f
        return (normal_subject_amount+ele_subject_amount+registration_course.amount.to_f)
      end
      return (ele_subject_amount+registration_course.amount.to_f)
    else
      return registration_course.amount.to_f
    end
  end

  def validate
    unless self.is_updating_status
      check_mandatory_fields
      if registration_course.is_subject_based_registration.present?
        subject_count = subject_ids.nil? ? 0 : subject_ids.count
        min_subject_count = registration_course.min_electives.nil? ? 0 : registration_course.min_electives
        max_subject_count = registration_course.max_electives.nil? ? 0 : registration_course.max_electives
        if subject_count < min_subject_count or subject_count > max_subject_count
          errors.add_to_base :select_elective_range
        end
      end

      errors.add(:date_of_birth, :cannot_be_future) if date_of_birth > Date.today
    end
  end

  #  def before_save
  #    if registration_course.subject_based_fee_colletion == true
  #      all_subjects = subject_ids
  #      all_subjects += normal_subject_ids unless normal_subject_ids.nil?
  #      total_amount = registration_course.course.subject_amounts.find(:all,:conditions => {:code => all_subjects}).flatten.compact.map(&:amount).sum
  #      self.amount = total_amount.to_f
  #    else
  #      self.amount = registration_course.amount.to_f
  #    end
  #  end

  def initialize_children
    applicant_guardians.each {|g| g.applicant=self}
    applicant_addl_values.each {|g| g.applicant=self}
    applicant_additional_details.each {|g| g.applicant=self}
    applicant_addl_attachments.each {|g| g.applicant=self}
    applicant_previous_data.applicant=self if applicant_previous_data.present?
  end

  def send_notification
    unless (self.being_allotted.present? and self.being_allotted == true)
      if (self.changed and self.changed.include?('status') and self.submitted==true)
        send_email_and_sms_alert
      end
    end
  end

  def send_email_and_sms_alert
    app_status = self.application_status
    if app_status.present? and app_status.notification_enabled==true
      status_text = app_status.is_default==true ? t(app_status.name) : app_status.name
      reg_course = self.registration_course
      reg_course_name = reg_course.display_name.present? ? reg_course.display_name : reg_course.course.course_name
      if self.phone2.present?
        sms_setting = SmsSetting.new()
        if sms_setting.application_sms_active
          recipients = []
          message = "#{t('dear')} #{self.first_name}, #{t('status_of_your_application_with_reg_no')} #{self.reg_no} #{t('for_text')} #{reg_course_name} #{t('updated_to')} #{status_text}. #{t('thanks')}"
          recipients.push self.phone2.split(',')
          if recipients.present?
            recipients.flatten! if recipients.present?
            recipients.uniq! if recipients.present?
            Delayed::Job.enqueue(SmsManager.new(message, recipients), {:queue => 'sms'})
          end
        end
      end
      if (self.email.present? and self.hostname.present?)
        begin
          Delayed::Job.enqueue(FedenaApplicantRegistration::ApplicantMail.new(self.full_name, self.email, self.reg_no, reg_course_name, status_text, self.school_details, self.hostname), {:queue => 'email'})
        rescue Exception => e
          puts "Error------#{e.message}------#{e.backtrace.inspect}"
          return
        end
      end
    end
  end

  def school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end

  def set_pending_status
    pending_status=ApplicationStatus.find_by_name("pending")
    unless pending_status.present?
      default_statuses = ApplicationStatus.create_defaults_and_return
      pending_status = default_statuses.select{|s| s.name=="pending"}.first
    end
    self.status=pending_status.id
  end

  def check_email
    !email.blank?
  end

  def check_guardian_addl_values
    guardian_addl_values = self.applicant_addl_values.select{|v| v.temp_guardian_ind.present?}
    if guardian_addl_values.present?
      app_guardians = self.applicant_guardians
      guardian_addl_values.each do|g|
        g.update_attributes(:applicant_guardian_id=>app_guardians[g.temp_guardian_ind].id,:temp_guardian_ind=>nil)
      end
    end
  end

  #  def check_course_is_active
  #    unless self.registration_course.is_active
  #      errors.add_to_base :error1
  #      false
  #    else
  #      true
  #    end
  #  end

  def generate_reg_no
    if (self.submitted == true and !self.reg_no.present?)
      last_applicant = Applicant.find(:first,:conditions=>["reg_no is not NULL"], :order=>"CONVERT(reg_no,unsigned) DESC")
      if last_applicant
        last_reg_no = last_applicant.reg_no.to_i
      else
        last_reg_no = 0
      end
      self.reg_no = last_reg_no.next
    end
  end

  def full_name
    if middle_name.present?
      "#{first_name} #{middle_name} #{last_name}".strip
    else
      "#{first_name} #{last_name}".strip
    end
  end

  def gender_as_text
    return "Male" if gender.downcase == "m"
    return "Female" if gender.downcase == "f"
  end

  def admit(batchid)
    flag = 0
    student_obj = nil
    msg = []
    student = nil
    Applicant.transaction do
      unless self.application_status.name == "alloted"
        attr = self.attributes.except('student_id')
        ["id","created_at","updated_at","status","reg_no","registration_course_id","applicant_previous_data_id",\
            "school_id","applicant_guardians_id","has_paid","photo_file_size","photo_file_name","photo_content_type","pin_number","print_token","subject_ids","is_academically_cleared","is_financially_cleared","amount","normal_subject_ids","submitted","subject_amounts"].each{|a| attr.delete(a)}
        student = Student.new(attr)
        app_prev_data = self.applicant_previous_data
        if app_prev_data.present? and app_prev_data.last_attended_school.present?
          prev_data = student.build_student_previous_data(:institution=>app_prev_data.last_attended_school,\
              :year=>"#{app_prev_data.qualifying_exam_year}",
            :course=>"#{app_prev_data.qualifying_exam}(#{app_prev_data.qualifying_exam_roll})",
            :total_mark=>app_prev_data.qualifying_exam_final_score	)
        end

        batch = Batch.find(batchid)
        if registration_course.is_subject_based_registration == true
          subject_codes = Set.new(batch.subjects.all(:conditions => {:is_deleted => false}).map(&:code))
          applicant_subject_codes = Set.new(((subject_ids.nil? ? [] : subject_ids) + (normal_subject_ids.nil? ? [] : normal_subject_ids)).compact.flatten)
          if applicant_subject_codes.subset?(subject_codes)
            student.batch_id = batch.id
            subjects = student.batch.subjects.find(:all,:conditions => {:code => subject_ids})
            subjects.map{|subject| student.students_subjects.build(:batch_id => student.batch_id,:subject_id => subject.id)}
          else
            student.errors.add_to_base :batch_not_contain_the_applicant_choosen
          end
        else
          student.batch_id = batchid
        end
        student.admission_no = User.next_admission_no("student")||"#{batch.course.code.gsub(' ','')[0..2]}-#{Date.today.year}-1"
        student.admission_date = Date.today
        student.photo = self.photo if self.photo.file?
        if student.errors.blank? and student.save
          if self.applicant_guardians.present?
            guardian_saved = 1
            self.applicant_guardians.each do|g|
              guardian_attr = g.attributes
              ["created_at","updated_at","applicant_id","school_id"].each{|a| guardian_attr.delete(a)}
              guardian = student.guardians.new(guardian_attr)
              guardian.ward_id= student.id
              unless guardian.save
                guardian_saved = 0
                msg << guardian.errors.full_messages
              end
            end
            if guardian_saved == 1
              msg << "#{t('alloted_to')}"
              flag = 1
            end
          else
            msg << "#{t('alloted_to')}"
            flag = 1
          end

          if self.applicant_addl_attachments.present?
            attachments = self.applicant_addl_attachments
            attachments.each do |att|
              if att.attachment.present?
                s =  student.student_attachments.build({:is_registered => true, :batch_id => student.batch_id})
                s.attachment = att.attachment
                s.attachment_content_type = att.attachment_content_type
                s.attachment_name = att.attachment_file_name
                s.save
              end
            end
          end
          prev_data.save if prev_data
          self.status = ApplicationStatus.find_by_name_and_is_default("alloted",true)
          self.batch_id = batch.id
          # linking applicant to student
          # Note:: no seed planned for older data [ hence for older data student_id will be nil]
          self.student_id = student.id
          self.save
          student_obj = student
        else
          msg << student.errors.full_messages
        end
      else
        msg << "#{t('applicant')} ##{self.reg_no} #{t('already_alloted')}"
      end

      copy_additional_details(student) unless student.nil?

      unless flag==1
        raise ActiveRecord::Rollback
      end
    end
    if flag==1
      guardian_record = Guardian.find_by_ward_id(student.id, :order=>"id ASC")
      if guardian_record.present?
        student.update_attributes(:immediate_contact_id=>guardian_record.id)
      end
    end

    ## trigger sync for master particular reporting
    # Note: an applicant paid fees is not synced to MasterParticularReport unless applicant is admited as student
    TransactionReportSync.trigger_report_sync_job(self.finance_transaction)

    [msg,student_obj,flag]
  end

  def copy_additional_details(student)
    #if registration_course.include_additional_details == true
    applicant_additional_details.each do |applicant_additional_detail|
      unless applicant_additional_detail.additional_field.nil?
        student.student_additional_details.build(:additional_field_id => applicant_additional_detail.additional_field_id,:additional_info => applicant_additional_detail.additional_info)
      end
    end
    student.save
    #end
  end

  def self.process_search_params(s)
    course_min_score = RegistrationCourse.find(s[:registration_course_id])
    if s[:status]=="eligible"
      s[:applicant_previous_data_qualifying_exam_final_score_gte]=course_min_score.minimum_score
      s.delete(:status)
    elsif s[:status]=="noteligible"
      s[:applicant_previous_data_qualifying_exam_final_score_lte]=course_min_score.minimum_score
      s.delete(:status)
    end
    s
  end

  def self.school_details
    name=Configuration.get_config_value('InstitutionName').present? ? "#{Configuration.get_config_value('InstitutionName')}," :""
    address=Configuration.get_config_value('InstitutionAddress').present? ? "#{Configuration.get_config_value('InstitutionAddress')}," :""
    Configuration.get_config_value('InstitutionPhoneNo').present?? phone="#{' Ph:'}#{Configuration.get_config_value('InstitutionPhoneNo')}" :""
    return (name+"#{' '}#{address}"+"#{phone}").chomp(',')
  end

  def self.commit(ids,batchid,act)
    if act.downcase=="allot"
      allot_to(ids,batchid)
    elsif act.downcase=="discard"
      discard(ids)
    end
  end

  def self.show_filtered_applicants(registration_course,start_date,end_date,search_params,selected_status,is_active)
    condition_keys = "submitted = true"
    condition_values = []
    if registration_course.present?
      condition_keys+=" and registration_course_id = ?"
      condition_values.push(registration_course.id)
    end
    if is_active==true
      condition_keys+=" and is_deleted = false"
    else
      condition_keys+=" and is_deleted = true"
    end
    if start_date.present?
      condition_keys+=" and date(created_at) >= ?"
      condition_values.push(start_date.to_date)
    end
    if end_date.present?
      condition_keys+=" and date(created_at) <= ?"
      condition_values.push(end_date.to_date)
    end
    if search_params.present?
      condition_keys+=" and (ltrim(first_name) LIKE ? OR ltrim(middle_name) LIKE ? OR ltrim(last_name) LIKE ?
                            OR reg_no = ? OR (concat(ltrim(rtrim(first_name)), \" \",ltrim(rtrim(last_name))) LIKE ? )
                              OR (concat(ltrim(rtrim(first_name)), \" \", ltrim(rtrim(middle_name)), \" \",ltrim(rtrim(last_name))) LIKE ? ))"
      3.times do
        condition_values.push("%#{search_params}%")
      end
      condition_values.push(search_params)
      2.times do
        condition_values.push("%#{search_params}%")
      end
    end
    if selected_status.present?
      condition_keys+=" and status = ?"
      condition_values.push(selected_status.id.to_s)
    end
    all_conditions = []
    all_conditions.push(condition_keys)
    all_conditions+=condition_values

    applicants = Applicant.find(:all,:conditions=>all_conditions,:include=>[:application_status,:batch],:order=>"created_at desc")

    return applicants

  end

  def self.search_by_order(registration_course, sorted_order, search_by)

    condition_keys = "registration_course_id = ?"
    condition_values = []
    condition_values << registration_course

    all_conditions=[]
    if search_by[:status].present?
      if search_by[:status]=="pending" or search_by[:status]=="alloted" or search_by[:status]=="discarded"
        condition_keys+=" and status = ?"
        condition_values << search_by[:status]
      end
    end
    if search_by[:created_at_gte].present?
      condition_keys+=" and created_at >= ?"
      condition_values << search_by[:created_at_gte].to_time.beginning_of_day
    end
    if search_by[:created_at_lte].present?
      condition_keys+=" and created_at <= ?"
      condition_values << search_by[:created_at_lte].to_time.end_of_day
    end

    all_conditions << condition_keys
    all_conditions += condition_values

    case sorted_order
    when "reg_no-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "reg_no desc")
    when "reg_no-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "reg_no asc")
    when "name-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "first_name desc")
    when "name-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "first_name asc")
    when "da_te-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "created_at desc")
    when "da_te-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "created_at asc")
    when "status-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "status desc")
    when "status-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "status asc")
    when "paid-descend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "has_paid desc")
    when "paid-ascend"
      applicants=self.find(:all, :conditions=>all_conditions, :order => "has_paid asc")
    else
      applicants=self.find(:all, :conditions=>all_conditions)
    end
    if search_by[:status]=="eligible"
      registration_course_data = RegistrationCourse.find_by_id(registration_course)
      unless registration_course_data.nil?
        applicants.reject!{|a| !(a.applicant_previous_data.present? and a.applicant_previous_data.qualifying_exam_final_score.to_i >=registration_course_data.minimum_score.to_i )}
      end
    elsif search_by[:status]=="noteligible"
      registration_course_data = RegistrationCourse.find_by_id(registration_course)
      unless registration_course_data.nil?
        applicants = applicants.select{|a| !(a.applicant_previous_data.present? and a.applicant_previous_data.qualifying_exam_final_score.to_i >= registration_course_data.minimum_score.to_i )}
      end
    end
    return applicants
  end

  def self.allot_to(ids,batchid)
    errs = []
    if ids.kind_of?(Array)
      apcts = self.find(ids)
      apcts.each do |apt|
        errs <<  apt.admit(batchid).first
      end
      errs
    elsif ids.kind_of?(Integer)
      self.find(ids).admit(batchid)
    else
      false
    end
  end



  def self.discard(ids)
    if ids.kind_of?(Array)
      self.update_all({:status=>"discarded"},{:id=>ids})
    elsif ids.kind_of?(Integer)
      self.find(ids).update_attributes(:status=>"discarded")
    else
      false
    end
    [[t('selected_applicants_discarded_successfully')],1]
  end

  def mark_paid
    if FedenaPlugin.can_access_plugin?("fedena_pay")
      @active_gateway = PaymentConfiguration.config_value("fedena_gateway")
      unless @active_gateway.present?
        transaction = create_finance_transaction_entry
        return transaction
      else
        logger = Logger.new("#{RAILS_ROOT}/log/payment_processor_error.log")
        begin
          retries ||= 0
          transaction = create_finance_transaction_entry("Online Payment")
        rescue ActiveRecord::StatementInvalid => er
          retry if (retries += 1) < 2
          logger.info "Error------#{er.message}----for Applicant--#{self.reg_no}" unless (retries += 1) < 2
        rescue Exception => e
          logger.info "Errror-----#{e.message}------for Applicant---#{self.reg_no}"
        end
      end
    else
      transaction = create_finance_transaction_entry
    end
    transaction
  end

  def update_payment_and_application_status(application_status,payment_status)
    if application_status.present?
      self.status = application_status.id
    end
    if payment_status == 1
      unless self.has_paid == true
        transaction = FinanceTransaction.new
        transaction.title = "Applicant Registration - #{self.reg_no} - #{self.full_name}"
        transaction.category_id = FinanceTransactionCategory.find_by_name('Applicant Registration').id
        transaction.amount = amount
        transaction.fine_included = false
        transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
        transaction.payee = self
        transaction.finance = self.registration_course
        # to prevent payment mode being blank
        transaction.payment_mode ||= 'Cash'
        transaction.save
        self.has_paid = true
      end
    end
    self.save
  end

  def create_finance_transaction_entry(payment_mode=String.new)
    transaction = FinanceTransaction.new
    transaction.title = "Applicant Registration - #{self.reg_no} - #{self.full_name}"
    transaction.category_id = FinanceTransactionCategory.find_by_name('Applicant Registration').id
    transaction.amount = amount
    transaction.fine_included = false
    transaction.transaction_date = FedenaTimeSet.current_time_to_local_time(Time.now).to_date
    transaction.payee = self
    transaction.finance = self.registration_course
    transaction.ledger_status = "PENDING" if self.payment_pending==true
    # to prevent payment mode being blank
    transaction.payment_mode = payment_mode.present? ? payment_mode : 'Cash'
    transaction.save
    if registration_course.enable_approval_system == true
      self.update_attributes(:has_paid=>true,:is_financially_cleared => true)
    else
      self.update_attributes(:has_paid=>true)
    end
    transaction
  end



  def mark_academically_cleared
    self.update_attributes(:is_academically_cleared => true)
  end


  def addl_fields
    @addl_field || {}
  end

  def addl_fields=(vals)
    @addl_field = vals
    vals.each_with_index do |(k,v),i|
      v = v.join(",") if v.kind_of?(Array)
      opt = self.applicant_addl_values.find(:first,:conditions=>{:applicant_addl_field_id=>k})
      unless opt.blank?
        opt.update_attributes(:option=>v)
      else
        self.applicant_addl_values.build(:applicant_addl_field_id=>k,:option=>v)
      end
    end
  end

  def addl_field_hash
    hsh={}
    self.applicant_addl_values.each do |a|
      hsh["#{a.applicant_addl_field_id}"] = a.reverse_value
    end
    @addl_field = hsh
  end

  def check_mandatory_fields
    mandatory_attributes = self.m_attr
    if mandatory_attributes.present?
      mandatory_attributes.split(", ").each do|m|
        self.errors.add(m.to_sym,"can't be blank.") unless self.send(m).present?
      end
    end
    #    fields=[]
    #    man_fields = self.registration_course.applicant_addl_field_groups.active
    #    man_fields.map{|f| fields <<  f.applicant_addl_fields.mandatory}
    #    fields.flatten.each do |f|
    #      errors.add_to_base("#{f.field_name} #{t('is_invalid')}") if @addl_field and @addl_field["#{f.id}"].blank?
    #    end
    errors.blank?
  end

  def save_print_token
    token = rand.to_s[2..8]
    self.update_attributes(:print_token => token)
  end

#  def finance_transaction
#    FinanceTransaction.first(:conditions=>{:payee_id=>self.id,:payee_type=>'Applicant'})
#  end

  def self.applicant_registration_data(params)
    reg_course = RegistrationCourse.find(params[:id])
    start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    statuses = ApplicationStatus.all
    selected_status = params[:selected_status].present? ? statuses.find_by_id(params[:selected_status].to_i) : ""
    applicants = Applicant.show_filtered_applicants(reg_course,start_date,end_date,search_params,selected_status,(params[:applicant_type]=="active" ? true : false))
    data = []
    each_row = []
    params[:applicant_type] == "active" ? each_row << "#{t('applicants_admins.applicant_s')}" : each_row << "#{t('archived_applicants')}"
    reg_course.display_name.present? ? each_row << "#{t('course')} : #{reg_course.display_name} (#{reg_course.course.course_name})" : each_row << "#{t('course')} : #{reg_course.course.course_name} (#{reg_course.course.code})"
    if search_params.present?
      each_row << "#{t('name_or_reg_no_like')} : #{search_params}"
    end
    if start_date.present?
      each_row << "#{t('start_date')} : #{format_date(start_date)}"
    end
    if end_date.present?
      each_row << "#{t('end_date')} : #{format_date(end_date)}"
    end
    if selected_status.present?
      each_row << "#{t('status')} : " + (selected_status.is_default == true ? "#{t(selected_status.name)}" : "#{selected_status.name}")
    end
    data << each_row
    data << ["#{t('applicants.reg_no')}","#{t('name')}","#{t('applicants_admins.da_te')}","#{t('status')}","#{t('applicants_admins.paid')}"]
    applicants.each do |applicant|
      applicant_status = ApplicationStatus.find(applicant.status)
      status = applicant_status.name
      data << [applicant.reg_no,applicant.full_name,(format_date(applicant.created_at.to_date) unless applicant.created_at.nil?),status,(applicant.has_paid? ? t('applicants_admins.y_es') : t('applicants_admins.n_o'))]
    end
    return data
  end

  def self.applicant_registration_detailed_data(params)
    reg_course = RegistrationCourse.find(params[:id])
    start_date = params[:start_date].present? ? params[:start_date].to_date : ""
    end_date = params[:end_date].present? ? params[:end_date].to_date : ""
    search_params = params[:name_search_param].present? ? params[:name_search_param] : ""
    statuses = ApplicationStatus.all
    selected_status = params[:selected_status].present? ? statuses.find_by_id(params[:selected_status].to_i) : ""
    applicants = Applicant.show_filtered_applicants(reg_course,start_date,end_date,search_params,selected_status,(params[:applicant_type]=="active" ? true : false))
    #    search_by =""
    #    if params[:search].present?
    #      search_by=params[:search]
    #    end
    #    @sort_order=""
    #    if params[:sort_order].present?
    #      @sort_order=params[:sort_order]
    #    end
    #    @results=Applicant.search_by_order(params[:id], @sort_order, search_by)
    #    if @sort_order==""
    #      @results = @results.sort_by { |u1| [u1.status,u1.created_at.to_date] }.reverse if @results.present?
    #    end
    #    @applicants = @results
    #    @course = RegistrationCourse.find(params[:id]).course
    application_section = reg_course.application_section
    unless application_section.present?
      application_section = ApplicationSection.find_by_registration_course_id(nil)
    end
    field_groups = ApplicantAddlFieldGroup.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",reg_course.id])
    applicant_addl_fields = ApplicantAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?) and is_active=true",reg_course.id],:include=>:applicant_addl_field_values)
    applicant_student_addl_fields = ApplicantStudentAddlField.find(:all,:conditions=>["(registration_course_id is NULL or registration_course_id = ?)",reg_course.id],:include=>[:student_additional_field=>:student_additional_field_options])
#    addl_attachment_fields = ApplicantAddlAttachmentField.find(:all,:conditions=>["registration_course_id is NULL or registration_course_id = ?",reg_course.id])
    default_fields = ApplicationSection::DEFAULT_FIELDS
    application_sections = application_section.present? ? application_section.section_fields : Marshal.load(Marshal.dump(ApplicationSection::DEFAULT_FORM))
    guardian_count = application_section.present? ? application_section.guardian_count : 1
    data = []
    each_row = []
    params[:applicant_type] == "active" ? each_row << "#{t('applicants_admins.applicant_s')}" : each_row << "#{t('archived_applicants')}"
    reg_course.display_name.present? ? each_row << "#{t('course')} : #{reg_course.display_name} (#{reg_course.course.course_name})" : each_row << "#{t('course')} : #{reg_course.course.course_name} (#{reg_course.course.code})"
    if search_params.present?
      each_row << "#{t('name_or_reg_no_like')} : #{search_params}"
    end
    if start_date.present?
      each_row << "#{t('start_date')} : #{format_date(start_date)}"
    end
    if end_date.present?
      each_row << "#{t('end_date')} : #{format_date(end_date)}"
    end
    if selected_status.present?
      each_row << "#{t('status')} : " + (selected_status.is_default == true ? "#{t(selected_status.name)}" : "#{selected_status.name}")
    end
    data << each_row
    each_row=Applicant.header_section(applicant_addl_fields,applicant_student_addl_fields,application_sections,guardian_count,reg_course)
    data << each_row
    each_row=Applicant.data_section(applicants,reg_course,field_groups,applicant_addl_fields,applicant_student_addl_fields,default_fields,application_sections,guardian_count)
    each_row.each do |row|
      data << row
    end
    return data
  end

  def self.header_section(applicant_addl_fields,applicant_student_addl_fields,application_sections,guardian_count,reg_course)
    data = []
    data << t('reg_no')
    guardian_index = 0
    application_sections.sort_by{|k| k[:section_order].to_i}.each do|a|
      if a[:fields].present?
        if a[:section_name]=="guardian_personal_details" or a[:section_name]=="guardian_contact_details"
          if a[:section_name]=="guardian_personal_details"
            while guardian_index < guardian_count
              guardian_index +=1
              a[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
                if ["true",true,"default_true"].include?(fld[:show_field])

                  if guardian_count == 1
                    if fld[:field_type]=="applicant_additional"
                    addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
                    unless addl_field.field_type == "attachment"
                      data << "#{t('guardian')} #{(addl_field.field_name) if addl_field.present?}"
                    end
                    elsif fld[:field_type]=="student_additional"
                      st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
                      if st_addl_field.present?
                        student_ad_field = st_addl_field.student_additional_field
                        data << "#{t('guardian')} #{(student_ad_field.name) if student_ad_field.present?}"
                      end
                    else
                      data << "#{t('guardian')} #{t(fld[:field_name])}"
                    end
                  else
                    if fld[:field_type]=="applicant_additional"
                      addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
                      unless addl_field.field_type == "attachment"
                        data << "#{t('guardian')} #{guardian_index} #{(addl_field.field_name) if addl_field.present?}"
                      end
                    elsif fld[:field_type]=="student_additional"
                      st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
                      if st_addl_field.present?
                        student_ad_field = st_addl_field.student_additional_field
                      data << "#{t('guardian')} #{guardian_index} #{(student_ad_field.name) if student_ad_field.present?}"
                      end
                    else
                      data << "#{t('guardian')} #{guardian_index} #{t(fld[:field_name])}"
                    end
                  end

                end
              end
              guardian_contact_section = application_sections.find{|as| as[:section_name] == "guardian_contact_details"}
              if (guardian_contact_section.present? and guardian_contact_section[:fields].present? and (guardian_contact_section[:fields].map{|s| s[:show_field]} - ["false",false]).present?)
                guardian_contact_section[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
                  if ["true",true,"default_true"].include?(fld[:show_field])
                    if fld[:field_type]=="applicant_additional"
                      addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
                      unless addl_field.field_type == "attachment"
                      data << "#{t('guardian')} #{guardian_index} #{(addl_field.field_name) if addl_field.present?}"
                      end
                    elsif fld[:field_type]=="student_additional"
                      st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
                      if st_addl_field.present?
                        student_ad_field = st_addl_field.student_additional_field
                      data << "#{t('guardian')} #{guardian_index} #{(student_ad_field.name) if student_ad_field.present?}"
                      end
                    else
                      data << "#{t('guardian')} #{guardian_index} #{t(fld[:field_name])}"
                    end
                  end
                end
              end
            end
          end
        else
          a[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
            if  a[:applicant_addl_field_group_id].present?
              if ["true",true,"default_true"].include?(fld[:show_field])
                if fld[:field_type]=="applicant_additional"
                  addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
                  data << (addl_field.field_name) if addl_field.present?
                elsif fld[:field_type]=="student_additional"
                  st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
                  if st_addl_field.present?
                    student_ad_field = st_addl_field.student_additional_field
                    data << (student_ad_field.name) if student_ad_field.present?
                  end
                end
              end
            else
              if ["true",true,"default_true"].include?(fld[:show_field])
                case fld[:field_type]
                when "default"
                  unless fld[:field_name] == "student_photo"
                    if fld[:field_name] == "choose_electives"
                      data << t(fld[:field_name]) if reg_course.is_subject_based_registration.present?
                    else
                      data << t(fld[:field_name])
                    end
                  end
                when "applicant_additional"
                  addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
                  unless addl_field.field_type == "attachment"
                    data << (addl_field.field_name) if addl_field.present?
                  end
                when "student_additional"
                  st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
                  if st_addl_field.present?
                    student_ad_field = st_addl_field.student_additional_field
                    data << (student_ad_field.name) if student_ad_field.present?
                  end
                end
              end
            end
          end
        end
      end
    end
    data << t('applicants_admins.paid')
    data.flatten
  end

  def self.data_section(applicants,reg_course,field_groups,applicant_addl_fields,applicant_student_addl_fields,default_fields,application_sections,guardian_count)
    data=[]
    applicants.each do |applicant|
      each_applicant=[]
      each_applicant << applicant.reg_no
      application_sections.sort_by{|k| k[:section_order].to_i}.each do|a|
        field_group = nil
        get_section = false
        if a[:applicant_addl_field_group_id].present?
          field_group = field_groups.find_by_id(a[:applicant_addl_field_group_id].to_i)
          if field_group.present?
            get_section = true if (a[:fields].present? and (a[:fields].map{|s| s[:show_field]} - ["false",false]).present?)
          end
        else
          get_section = true if (a[:fields].present? and (a[:fields].map{|s| s[:show_field]} - ["false",false]).present?)
          get_section = (reg_course.is_subject_based_registration.present? ? true : false) if a[:section_name]=="elective_subjects"
        end
        if get_section == true
          if a[:section_name]=="guardian_personal_details" or a[:section_name]=="guardian_contact_details"
            if a[:section_name]=="guardian_personal_details"
              guardian_array = []
              guardian_contact_section = application_sections.find{|as| as[:section_name] == "guardian_contact_details"}
              get_contact_section = false
              get_contact_section = true if (guardian_contact_section.present? and guardian_contact_section[:fields].present? and (guardian_contact_section[:fields].map{|s| s[:show_field]} - ["false",false]).present?)
              applicant_guardian_count = applicant.applicant_guardians.count
              applicant.applicant_guardians.each do|guardian|
                each_applicant << applicant.get_data_section(a,guardian,applicant_addl_fields,applicant_student_addl_fields ,default_fields,reg_course,applicant)
                each_applicant << (applicant.get_data_section(guardian_contact_section,guardian,applicant_addl_fields,applicant_student_addl_fields ,default_fields,reg_course,applicant)) if get_contact_section == true
              end
              while applicant_guardian_count < guardian_count do
                applicant_guardian_count += 1
                a[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
                  if ["true",true,"default_true"].include?(fld[:show_field])
                    guardian_array << ""
                  end
                end
                guardian_contact_section = application_sections.find{|as| as[:section_name] == "guardian_contact_details"}
                if (guardian_contact_section.present? and guardian_contact_section[:fields].present? and (guardian_contact_section[:fields].map{|s| s[:show_field]} - ["false",false]).present?)
                  guardian_contact_section[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
                    if ["true",true,"default_true"].include?(fld[:show_field])
                      guardian_array << ""
                    end
                  end
                end
              end
              each_applicant << guardian_array
            end
          else
            if a[:section_name] == "previous_institution_details"
              each_applicant << applicant.get_data_section(a,applicant.applicant_previous_data,applicant_addl_fields,applicant_student_addl_fields,default_fields,reg_course,applicant)
            elsif ["student_personal_details","student_communication_details","elective_subjects"].include?(a[:section_name])
              each_applicant << applicant.get_data_section(a,applicant,applicant_addl_fields,applicant_student_addl_fields ,default_fields,reg_course,applicant)
            else
              each_applicant << applicant.get_data_section(a,nil,applicant_addl_fields,applicant_student_addl_fields ,default_fields,reg_course,applicant)
            end
          end
        end
      end
      each_applicant << (applicant.has_paid? ? t('applicants_admins.y_es') : t('applicants_admins.n_o'))
      data << each_applicant.flatten
    end
    data
  end

  def get_data_section(a,section_object,applicant_addl_fields,applicant_student_addl_fields,default_fields,reg_course,applicant)
    data=[]
    if a[:applicant_addl_field_group_id].present?
      a[:fields].sort_by{|l| l[:field_order].to_i}.each do|fld|
        if ["true",true,"default_true"].include?(fld[:show_field])
          case fld[:field_type]
          when "applicant_additional"
            addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
            if addl_field.present?
              addl_value = applicant.applicant_addl_values.find_by_applicant_addl_field_id(addl_field.id)
              unless addl_field.field_type == "attachment"
                if  addl_field.field_type == "date"
                  data << ((addl_value.present? and addl_value.option.present?) ? format_date(addl_value.value.to_date,:format=>:long) : "" )
                else
                  data << "#{((addl_value.present? and addl_value.option.present?) ? addl_value.value : "")} #{(addl_field.field_type == "singleline" and addl_value.present? and addl_value.option.present?) ? addl_field.suffix : ""}"
                end
              end
            end
          when "student_additional"
            st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
            if st_addl_field.present?
              student_ad_field = st_addl_field.student_additional_field
              if student_ad_field.present?
                addl_value = self.applicant_additional_details.find_by_additional_field_id(st_addl_field.student_additional_field_id)
                data << ((addl_value.present? and addl_value.additional_info.present?) ? addl_value.additional_info : "")
              end
            end
          end
        end
      end
    else
      default_section = default_fields[a[:section_name].to_sym]
      a[:fields].sort_by{|l| l[:field_order].to_i}.each_with_index do|fld,ind|
        if ["true",true,"default_true"].include?(fld[:show_field])
          if fld[:field_type] == "default"
            if default_section.present?
              field_details = default_section[:fields][fld[:field_name].to_sym]
              f_attr = (field_details[:field_attr].present? ? field_details[:field_attr] : fld[:field_name])
              if section_object.present?
                if ["country_id","nationality_id"].include?(f_attr.to_s)
                  data << (section_object.send(f_attr.to_s).present? ? Country.find(section_object.send(f_attr.to_s)).name : "")
                elsif f_attr.to_s == "gender"
                  data << (section_object.send(f_attr.to_s).present? ? (section_object.send(f_attr.to_s).downcase=="m" ? t('male') : t('female')) : "")
                elsif f_attr.to_s == "relation"
                  data << (section_object.send(f_attr.to_s).present? ? section_object.translated_relation : "")
                elsif f_attr.to_s == "student_category_id"
                  unless section_object.send(f_attr.to_s).present?
                    data << ""
                  else
                    data << StudentCategory.find(section_object.send(f_attr.to_s)).name
                  end
                elsif f_attr.to_s == "subject_ids"
                  data << (section_object.send(f_attr.to_s).present? ? section_object.send(f_attr.to_s).map{|s| latest_subject_name(s,reg_course.course_id)}.join(", ") : "")
                else
                  unless fld[:field_name] == "student_photo"
                    data << (section_object.send(f_attr.to_s).present? ? (section_object.send(f_attr.to_s).class.name == "Date" ? format_date(section_object.send(f_attr.to_s),:format=>:long) : section_object.send(f_attr.to_s)) : "")
                  end
                end
              end
            end
          else
            case fld[:field_type]
            when "applicant_additional"
              addl_field = applicant_addl_fields.find_by_id(fld[:field_name].to_i)
              if addl_field.present?
                if ["guardian_personal_details","guardian_communication_details"].include?(a[:section_name])
                  addl_value = self.applicant_addl_values.select{|s| (s.applicant_addl_field_id==addl_field.id and s.applicant_guardian_id==section_object.id)}.first
                else
                  addl_value = self.applicant_addl_values.find_by_applicant_addl_field_id(addl_field.id)
                end
                unless addl_field.field_type == "attachment"
                  if addl_field.field_type == "date"
                    data << ((addl_value.present? and addl_value.option.present?) ? format_date(addl_value.value.to_date,:format=>:long) : "")
                  else
                    data << "#{((addl_value.present? and addl_value.option.present?) ? addl_value.value : "")} #{(addl_field.field_type == "singleline" and addl_value.present? and addl_value.option.present?) ? addl_field.suffix : ""}"
                  end
                end
              end
            when "student_additional"
              st_addl_field = applicant_student_addl_fields.find{|k| k[:student_additional_field_id]==fld[:field_name].to_i}
              if st_addl_field.present?
                student_ad_field = st_addl_field.student_additional_field
                if student_ad_field.present?
                  addl_value = self.applicant_additional_details.find_by_additional_field_id(st_addl_field.student_additional_field_id)
                  data << ((addl_value.present? and addl_value.additional_info.present?) ? addl_value.additional_info : "")
                end
              end
            end
          end
        end
      end
    end
    data.flatten
  end

  def latest_subject_name (code,course_id)
    Subject.find_all_by_code_and_batch_id(code,Batch.find_all_by_course_id(course_id)).last.name
  end

  def self.search_by_registration_data(params)
    @search_params = params[:reg_no]
    @applicants = Applicant.show_filtered_applicants(nil,nil,nil,@search_params,nil,true)
    data = []
    data << [t('applicants.reg_no'),t('course_name'),t('name'),"#{t('applicants_admins.da_te')}",t('status'),t('applicants_admins.has_paid_fees')]
    @applicants.each do |applicant|
      data << [applicant.reg_no,applicant.registration_course.try(:course).try(:full_name),applicant.full_name,(format_date(applicant.created_at.to_date) unless applicant.created_at.nil?),(applicant.application_status.is_default == true ? (applicant.application_status.name == "alloted" ? (applicant.batch_id.present? ? "#{t('alloted')} - #{applicant.batch.full_name}" : "#{t('alloted')}") : t(applicant.application_status.name)) : applicant.application_status.name),(applicant.has_paid? ? t('applicants_admins.y_es') : t('applicants_admins.n_o'))]
    end
    return data
  end
  def self.applicant_guardian_phone(applicants)
    guardian_phone_numbers = []
    applicants.each do |a|
      phone_numbers = a.applicant_guardians.collect(&:mobile_phone).reject(&:blank?)
      guardian_phone_numbers << phone_numbers
    end
    guardian_phone_numbers.flatten
  end

  def self.applicant_guardian_email(applicants)
    guardian_emails = []
    applicants.each do |a|
      emails = a.applicant_guardians.collect(&:email).reject(&:blank?)
      guardian_emails << emails.flatten
    end
    guardian_emails.flatten
  end
  
  def self.applicant_guardian_ids(applicants)
    g_ids= []
    applicants.each do |a|
      g_ids << a.applicant_guardians.collect(&:id)
    end  
    g_ids.flatten
  end  
end
