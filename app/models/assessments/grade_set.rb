class GradeSet < ActiveRecord::Base
  
  has_many :grades
  has_many :assessment_groups
  
  accepts_nested_attributes_for :grades,:allow_destroy => true, :reject_if => 
    lambda { |a| a[:name].blank? and a[:minimum_marks].blank? and a[:credit_points].blank? and a[:description].blank? }
  
  validates_presence_of :name
  validates_uniqueness_of :name, :case_sensitive => false
  
  validate :check_grades
  validate :check_grade_marks
  before_save :set_credit_points
  
  def validate
    errors.add(:base, :dependencies_exist) if dependencies_present?
  end
  
  def self.default
    first(:conditions => {:is_default => true})
  end
  
  def make_default
    self.class.update_all('is_default = false', ["school_id = ?", MultiSchool.current_school.id])
    self.reload
    self.update_attribute(:is_default, true)
  end
  
  def check_grades
    grades_list = grades.select{|a| !a.marked_for_destruction?}.group_by{|gr| gr.name.downcase}
    grades_list.each do |name, all_grades|
      if name.present? and all_grades.length > 1
        all_grades.each{|gr| gr.errors.add(:name, :taken)}
        errors.add(:base, :dependencies_exist)
      end
    end
  end
  
  def check_grade_marks
    grades_list = grades.select{|gr| (!gr.marked_for_destruction? and gr.minimum_marks)}.group_by{|gr| gr.minimum_marks.to_f}
    grades_list.each do |mark, all_grades|
      if all_grades.length > 1
        all_grades.each{|gr| gr.errors.add(:minimum_marks, :taken)}
        errors.add(:base, :dependencies_exist)
      end
    end
  end

  def grades_count
    grades.length
  end
  
  def grade_type
    (direct_grade? ? t('direct_grade') : 
        (enable_credit_points? ? t('marks_based_grades_with_credit_points') : 
          t('marks_based_grades') ) )
  end
  
  def set_credit_points
    self.enable_credit_points = false if direct_grade?
    return
  end
  
  def grades_json
    grades.collect {|grade| {:grade=>grade.name,:score=>grade.minimum_marks, :grade_id => grade.id}}
  end
  
  def dependencies_present?
    assessment_groups.present? or present_in_report_settings?
  end
  
  def present_in_report_settings?
#    AssessmentReportSetting.find_by_setting_key_and_setting_value('GradeSetId', self.id.to_s).present?
    unless self.new_record?
      keys = ['ScholasticGradeScale','CoScholasticGradeScale','GradeSetId']
      AssessmentReportSetting.all(:conditions => {:setting_key => keys, :setting_value => self.id.to_s}).present?
    else
      return false
    end
  end
  
  def grade_string_for(mark)
    grade_obj = grades.present? ? grades.sorted_marks.select{|g| g.minimum_marks.to_f <= mark.to_f}.first : nil
    grade_obj.nil? ? "No Grade" : grade_obj.name
  end

  def select_grade_for(grades_list, mark)
    grades_list.present? ? grades_list.select{|g| g.minimum_marks.to_f <= mark.to_f}.first : nil
  end
end
