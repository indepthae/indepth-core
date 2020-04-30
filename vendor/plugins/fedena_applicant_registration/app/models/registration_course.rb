class RegistrationCourse < ActiveRecord::Base
  serialize :additional_field_ids
  belongs_to :course
  has_one :application_instruction, :dependent=>:destroy
  has_one :application_section, :dependent=>:destroy
  delegate :course_name,:code,:to=>:course,:prefix=>false,:allow_nil=>true
  belongs_to :financial_year

  validates_presence_of :course_id
  validates_uniqueness_of :course_id,:message=>:already_added

  validates_numericality_of :amount,:allow_nil=>true, :greater_than_or_equal_to => 0

  named_scope :active,{:conditions=>{:is_active=>true,:courses=>{:is_deleted=>false}},:joins=>:course}

  has_many :applicant_addl_field_groups, :dependent=>:destroy
  has_many :applicants, :dependent=>:destroy
  accepts_nested_attributes_for :application_instruction
  # to link financial year
  before_create :set_financial_year, :set_master_fee
  # fetches current financial year and sets same
  def set_financial_year
    self.financial_year_id = FinancialYear.current_financial_year_id
  end
  # fetches master particular created via seed
  # set same with registration course
  def set_master_fee
    master = MasterFeeParticular.registration_course.last
    self.master_fee_particular_id = master.id if master.present?
  end

  def before_destroy
    if self.can_be_deleted?
      true
    else
      errors.add_to_base :registration_course_is_in_use_and_cannot_be_deleted
      false
    end
  end

  def can_be_deleted?
    if Applicant.exists?(:registration_course_id=>self.id,:submitted=>true)
      false
    else
      true
    end
  end


  def is_subject_based
    self.is_subject_based_registration.to_s == "true"
  end

  def asset_field_names
    hsh=ActiveSupport::OrderedHash.new(applicant_addl_fields.first. make_hash_default_name)
    related_options=[]
    applicant_addl_fields.each do |af|
      case af.field_type
      when 'belongs_to'
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"]=af.attributes
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh[af.field_name.downcase.gsub(' ','_')+"_id"].merge!({"related_options"=>related_options})
      when 'has_many'
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"]=af.attributes
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"].merge!({"related"=>af.field_name.downcase.gsub(' ','_')+"s"})
        related_options=af.asset_field_options.map{|ae| [ae.default_field,ae.id]}
        hsh[af.field_name.downcase.gsub(' ','_')+"_ids"].merge!({"related_options"=>related_options})
      else
        hsh[af.field_name.downcase.gsub(' ','_')]=af.attributes
      end
    end
    hsh
  end



  def manage_pin_system(status)
    @course_pin = CoursePin.find_by_course_id(course_id)
    if @course_pin.nil?
      @course_pin = CoursePin.create(:course_id => course_id,:is_pin_enabled => status)
    else
      @course_pin.update_attributes(:is_pin_enabled => status)
    end
  end

  def pin_enabled_status
    @course_pin = CoursePin.find_by_course_id(course_id)
    if @course_pin.nil?
      false
    else
      @course_pin.is_pin_enabled
    end
  end

  def get_elective_subjects_and_amount
    subjects = {}
    ele_subjects = self.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    subject_amounts = self.course.subject_amounts
    elective_subject_amounts = subject_amounts.find_all_by_code(ele_subjects)
    ele_subjects.each do |sub|
      subject=elective_subject_amounts.find_by_code(sub)
      subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
    end
    return subjects
  end

  def get_applicant_elective_subject_amounts_hash(ele_subjects_code)
    subjects = {}
    subject_amounts = self.course.subject_amounts
    elective_subject_amounts = subject_amounts.find_all_by_code(ele_subjects_code)
    ele_subjects_code.each do |sub|
      subject=elective_subject_amounts.find_by_code(sub)
      subjects.merge!(sub=>subject ? subject.amount.to_f: 0 )
    end
    return subjects
  end

  def get_elective_subjects_amount
    ele_subjects = self.course.batches.active.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq
    subject_amounts = self.course.subject_amounts
    elective_subject_amounts = subject_amounts.find_all_by_code(ele_subjects).flatten.compact.map(&:amount).sum.to_f
    return elective_subject_amounts
  end

  def get_major_subjects_amount
    normal_subjects=self.course.batches.active.map(&:normal_batch_subject).flatten.compact.map(&:code).compact.flatten.uniq
    subject_amounts = self.course.subject_amounts
    normal_subject_amount=subject_amounts.find(:all,:conditions => {:code => normal_subjects}).flatten.compact.map(&:amount).sum.to_f
    return normal_subject_amount
  end

  def validate
    if self.is_subject_based_registration?
      unless self.course.nil?
        if self.course.batches.map(&:all_elective_subjects).flatten.compact.map(&:code).compact.flatten.uniq.blank?
          errors.add_to_base :no_elective_subjects
          return false
        elsif self.min_electives.to_i > self.max_electives.to_i
          errors.add_to_base :min_cannot_be_greater_than_max
        else
          return true
        end
      else
        return false
      end
    end

  end

  class << self
    def has_unlinked_courses?
      RegistrationCourse.count(:conditions => "master_fee_particular_id IS NULL") > 0
    end
  end
end
