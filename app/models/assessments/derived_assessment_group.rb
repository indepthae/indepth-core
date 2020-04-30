# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class DerivedAssessmentGroup < AssessmentGroup
  has_one :derived_assessment_group_setting, :dependent => :destroy
  accepts_nested_attributes_for :derived_assessment_group_setting,:allow_destroy => true
  has_many :derived_assessment_groups_associations,:dependent => :destroy, :order => 'priority , id'
  has_many :assessment_groups, :through => :derived_assessment_groups_associations, 
    :order => 'derived_assessment_groups_associations.priority , derived_assessment_groups_associations.id', 
    :select => 'assessment_groups.*, derived_assessment_groups_associations.priority'
  accepts_nested_attributes_for :derived_assessment_groups_associations
  
  validates_presence_of  :grade_set_id, :if => Proc.new { |p| ([2, 3].include? p.scoring_type.to_i) }, :unless => :no_exam
  validates_presence_of  :maximum_marks, :if => Proc.new { |p| ([1, 3].include? p.scoring_type.to_i) }, :unless => :no_exam
  validates_presence_of  :minimum_marks, :if => Proc.new { |p| (p.scoring_type.to_i == 1) }, :unless => :no_exam
  validate :check_min_and_max, :unless => :no_exam
  validate :presence_of_assessment_groups
  validate :presence_of_weightage, :unless => :no_exam
  validate :presence_of_ag_count, :unless => :no_exam
  named_scope :with_settings, :include => :derived_assessment_group_setting
  
  before_validation :save_settings, :build_assessment_group, :if => Proc.new{|dag| dag.derived_assessment_attributes.present?}
  attr_accessor :derived_assessment_attributes, :max_marks, :min_marks, :assessment_group_id, :weightage, :ag_count, :connectable_assessments
  
  Setting = Struct.new(:formula, :weightage, :report_settings, :other_settings)
  
  def final_planner_assessment?
    self.is_final_term? and self.parent_type == 'AssessmentPlan'
  end
  
  def check_min_and_max
    if [1, 3].include? self.scoring_type.to_i
      errors.add(:max_marks, :blank)  if self.maximum_marks.blank?
    end
    if self.scoring_type.to_i == 1
      errors.add(:min_marks, :blank) if self.minimum_marks.blank?
    end
  end
  
  def build_connectable_groups
    self.connectable_assessments = assessment_plan.connectable_assessments
  end
  
  def get_submitted_batches(course,current_user=nil)
    if current_user.privileges.include?(Privilege.find_by_name("ManageGradebook")) or current_user.admin? or current_user.privileges.include?(Privilege.find_by_name("GradebookMarkEntry"))
      all_batches = course.batches_in_academic_year(self.academic_year_id)
    elsif  current_user.is_a_batch_tutor? 
      employee = current_user.employee_entry
      batch_ids = employee.batches.collect(&:id)
      all_batches = course.batches.find(:all,:conditions=>["batches.id in (?) and academic_year_id = ?",batch_ids,self.academic_year_id])
    end
    normal_groups = self.all_assessment_groups
    derived_groups = self.assessment_groups.derived_groups
    batches_list = {}
    all_batches.each do |batch|
      derived_group_batch = self.assessment_group_batches.detect{|agb|(agb.assessment_group_id == self.id and agb.batch_id == batch.id) }
      status = []
      normal_groups.each do |group|
        group_batch = group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == group.id and agb.batch_id == batch.id)}
        if group_batch.present? and  group_batch.childrens_present?
          status << "#{group.name} - #{t('no_marks_entered')}" unless group_batch.marks_added
        else
          status << "#{group.name} - #{t('not_scheduled')}"
        end
      end
      derived_groups.each do |d_group|
        group_batch = d_group.assessment_group_batches.detect{|agb| (agb.assessment_group_id == d_group.id and agb.batch_id == batch.id)}
        unless group_batch.present? and group_batch.try(:marks_added)
          status << ("#{d_group.name} - #{t('marks_not_calculated')}")
        end
      end
      status << "#{t('no_examgroups_present')}" if normal_groups.length == 0
      status_code = derived_group_batch.try(:submission_status)
      batches_list[batch.id] = {:selected => false, :name => batch.name, 
        :students => batch.students.length,
        :can_calculate => status.empty? ? ((status_code == 1) ? false : true) : false,
        :status => status.empty? ? (derived_group_batch.present? ? derived_group_batch.try(:submission_status_text):  t('marks_not_calculated'))  : status.join(', '),
        :last_error => nil,
        :status_code => status.empty? ? status_code : nil
      }
    end
    batches_list
  end
  
  def get_subject_list(batch_ids)
    hsh = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    assessment_group_batches.all(:conditions=>["batch_id in (?)",batch_ids], :joins => :converted_assessment_marks, :select => 'distinct assessment_group_batches.*').each do |agb|
      hsh[agb.batch_id] = agb.converted_assessment_marks.all(:group => 'markable_id', :include => :markable).collect(&:markable)
    end
    hsh
  end
  
  def build_derived_marks(batch_id,subject_id)
    agb = self.assessment_group_batches.find_by_batch_id(batch_id)
    if agb
      agb.converted_assessment_marks.all(:conditions=>["markable_id = ? and markable_type= ?",subject_id,'Subject'],:joins=>:student,:include=>:student)
    else
      []
    end
  end
  
  def calculate_derived_marks(batch_id)
    agb = AssessmentGroupBatch.find_or_initialize_by_batch_id_and_assessment_group_id(batch_id, self.id)
    agb.submit_derived_marks
  end
  
  def presence_of_assessment_groups
    unless no_exam
      errors.add(:assessment_group_id, :select_atleast_two_assessment_group)  if self.assessment_group_ids.blank? or self.assessment_group_ids.count < 2
    end
  end
  
  def presence_of_weightage
    if percentage_formula?
      weightage = self.weightage
      error = self.assessment_group_ids.select { |g_id| weightage[g_id.to_s].blank? }
      if error.present?
        errors.add(:weightage, :fill_weightages)
      else
        sum_of_weightage = weightage.values.map{|w| w.to_f.round(2)}.sum
        errors.add(:weightage, :sum_of_weightage_error) if sum_of_weightage != 100
      end
    end
  end
  
  def presence_of_ag_count
    if avgerage_best_formula?
      ag_count = get_settings(:ag_count)
      if ag_count.present?
        errors.add(:ag_count, :ag_count_greater_than_ags) if ag_count.to_i > assessment_group_ids.count
      else
        errors.add(:ag_count, :fill_weightages)
      end
    end
  end
  
  def percentage_formula?
    self.formula == 'percentage' and self.assessment_group_ids.present?
  end
  
  def avgerage_best_formula?
    self.formula == 'avg_bestof' and self.assessment_group_ids.present?
  end
  
  def save_settings
    self.attributes = extract_sub_hash(self.derived_assessment_attributes, attribute_names )
    self.derived_assessment_group_setting_attributes = get_group_detailed_settings
  end
  
  def build_assessment_group
    self.assessment_group_ids = self.derived_assessment_attributes['assessment_group_id']
  end
  
  def extract_sub_hash(hash, extract)
    sub_hsh = hash.select{|key, value| extract.include? key}
    Hash[sub_hsh.to_a]
  end
  
  def get_group_detailed_settings
    {
      :id => self.derived_assessment_group_setting.try(:id),
      :value=>Setting.new(
        self.derived_assessment_attributes["formula"],
        self.derived_assessment_attributes["weightage"],
        self.derived_assessment_attributes["report_settings"],
        self.derived_assessment_attributes["other_settings"]
      )
    }
  end
  
  def formula
    derived_assessment_group_setting.present? ? derived_assessment_group_setting.formula : ''
  end
  
  def weightage
    derived_assessment_group_setting.present? ? derived_assessment_group_setting.weightage : {}
  end
  
  def show_child_in_assessment_report?
    derived_assessment_group_setting.present? ? (derived_assessment_group_setting.report_settings.include? 'exam_report') : false
  end
  
  def show_child_in_term_report?
    derived_assessment_group_setting.present? ? (derived_assessment_group_setting.report_settings.include? 'term_report') : false
  end
  
  def show_child_in_planner_report?
    derived_assessment_group_setting.present? ? (derived_assessment_group_setting.report_settings.include? 'plan_report') : false
  end
  
  def report_settings
    derived_assessment_group_setting.present? ? derived_assessment_group_setting.report_settings : []
  end
  
  def other_settings
    derived_assessment_group_setting.present? ? derived_assessment_group_setting.other_settings : {}
  end
  
  def get_settings(config_value)
    other_settings[config_value]
  end
  
  def show_percentage?
    get_settings(:show_percentage) == 'true'
  end
  
  def settings_as_hash
    settings = Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    setting = derived_assessment_group_setting
    settings[:formula] = setting.try(:formula)
    settings[:weightage] = setting.try(:weightage)
    settings[:report_settings] = setting.try(:report_settings)
    settings[:other_settings] = setting.try(:other_settings)
    return settings
  end
  
  def build_settings
    self.build_derived_assessment_group_setting
    save_settings
  end
  
  def self.fetch_all_assessments(plan, term) 
    if term.present?
      all(:conditions=>{:parent_id => term.id,:parent_type => 'AssessmentTerm', :is_final_term => false})
    else
      all(:conditions=>{:assessment_plan_id => plan.id , :parent_type => 'AssessmentPlan', :is_final_term => false})
    end
  end
  
  
#  def get_assessment_groups_for_planner_report
#    childrens = []
#    assessment_groups.each do |group|
#      childrens += group.assessment_groups if group.derived_assessment? and group.show_child_in_planner_report?
#      childrens << group
#    end
#    return childrens.uniq
#  end
  
  def all_assessment_groups
    extract_assessment_groups(assessment_groups.all(:include => :assessment_group_batches))
  end
  
  def extract_assessment_groups(assessment_groups)
    children = []
    assessment_groups.each do |group|
      unless group.derived_assessment?
        children << group 
      else
#        children += group.assessment_groups
        children += extract_assessment_groups(group.assessment_groups.all(:include => :assessment_group_batches))
      end
    end
    return children.uniq
  end
  
  def all_assessment_groups_for_report(type)
    self.class.extract_displayable_assessment_groups(assessment_groups.all(:include => {:assessment_group_batches => {:subject_attribute_assessments => {:attribute_assessments => :assessment_attribute}}}),type)
  end
  
  def has_assessments_for_all_subjects(batch)
    batch_groups = batch.assessment_group_batches
    sub_list = []
    all_assessment_groups.each do |group|
      b_group = batch_groups.detect{|g| g.assessment_group_id == group.id}
      sub_list << b_group.try(:subjects_list )||[]
    end
    (sub_list.uniq.length == 1)
  end
  
  
  def calculate_final_score(marks, assess_max_mark = nil)
    amm = assess_max_mark || maximum_marks.to_f
    send("calculate_#{formula}", marks, amm)
  end
  
  def calculate_sum(marks,assess_max_mark)
    obtained_marks = marks.map{|id, values| values[:mark].to_f}
    max_marks = marks.map{|id, values| values[:max_mark].to_f}
    (obtained_marks.sum/max_marks.sum)*assess_max_mark
  end
  
  def calculate_average(marks,assess_max_mark)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    (converted_marks.sum/marks.length)
  end
  
  def calculate_bestof(marks,assess_max_mark)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    converted_marks.max
  end
  
  def calculate_avg_bestof(marks,assess_max_mark)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    converted_marks = converted_marks.sort
    ag_count = get_settings(:ag_count).try(:to_i)
    if ag_count
      ag_count = (ag_count >= converted_marks.size) ?  converted_marks.size : ag_count
      best_values = converted_marks[-ag_count..converted_marks.size]
      best_values.present? ? (best_values.sum.to_f/best_values.length) : 0
    else
      converted_marks.present? ? (converted_marks.sum.to_f/converted_marks.length) : 0
    end
  end
  
  def calculate_percentage(marks,assess_max_mark)
    all_marks = []
    weightage.each do |id, percentage|
      percent = marks[id.to_i].present? ? marks[id.to_i][:converted_mark]*percentage.to_f.round(2)/100 : 0
      all_marks << (percent)
    end
    all_marks.sum
  end
  
  def grouped_associations
    derived_assessment_groups_associations.all(:joins => :assessment_group, :select => 'derived_assessment_groups_associations.*, assessment_groups.parent_id').group_by(&:parent_id)
  end
  
  class << self
    def extract_displayable_assessment_groups(assessment_groups,type)
      children = []
      assessment_groups.each do |group|
        if group.derived_assessment? and group.send("show_child_in_#{type}_report?")
          children += extract_displayable_assessment_groups(group.assessment_groups.all(:include => {:assessment_group_batches => {:subject_attribute_assessments => {:attribute_assessments => :assessment_attribute}}}), type)
          children << group
        else
          children << group 
        end
      end
      return children.uniq
    end
  end
end
