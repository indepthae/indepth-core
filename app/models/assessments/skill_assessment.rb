class SkillAssessment < ActiveRecord::Base
  belongs_to :subject
  belongs_to :assessment_group_batch
  belongs_to :subject_skill
  belongs_to :subject_assessment
  belongs_to :higher_skill_assessment, :class_name=>"SkillAssessment", :foreign_key=>"higher_assessment_id"
  has_many :sub_skill_assessments, :class_name=>"SkillAssessment", :foreign_key=>"higher_assessment_id", :dependent => :destroy
  has_many :assessment_marks, :as => :assessment,:dependent => :destroy
  accepts_nested_attributes_for :assessment_marks, :allow_destroy => true, :reject_if => lambda{|a| ((a[:is_absent] == "false") and a[:id].blank? and a[:grade_id].blank? and a[:marks].blank?) }
  accepts_nested_attributes_for :sub_skill_assessments, :allow_destroy => true
  before_save :check_marks
  
  def calculate_skill_mark(marks_hash,group, subject_maximum, grades)
    grade_set = group.grade_set
    if subject_skill.calculate_final? and sub_skill_assessments.present? and !group.grade_type?
      extra_keys = marks_hash.keys - sub_skill_assessments.collect(&:subject_skill_id)
      marks = send("calculate_#{subject_skill.formula}", marks_hash.except(* extra_keys))
      percentage = ((marks.to_f/subject_skill.maximum_marks.to_f)*100)
      mark_grade = grade_set.select_grade_for(grades, percentage) if grade_set
      {:mark => marks, :grade => mark_grade.try(:name), 
                :credit_points => mark_grade.try(:credit_points), :max_mark => subject_skill.maximum_marks,
                :converted_mark => ((marks.to_f/subject_skill.maximum_marks.to_f)*subject_maximum.to_f).round(2)}
    end 
  end
  
  def calculate_sum(marks)
    obtained_marks = marks.map{|id, values| values[:mark].to_f}
    max_marks = marks.map{|id, values| values[:max_mark].to_f}
    ((obtained_marks.sum/max_marks.sum)*subject_skill.maximum_marks.to_f).round(2)
  end
  
  def calculate_average(marks)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    (converted_marks.sum/marks.length).to_f.round(2)
  end
  
  def check_marks
    assessment_marks.each do |am|
      am.mark_for_destruction if !am.new_record? and !am.is_absent and am.marks.blank? and am.grade_id.blank? and am.grade.blank?
    end
  end
  
  
  def calculate_bestof(marks)
    converted_marks = marks.map{|id, values| values[:converted_mark].to_f}
    converted_marks.max
  end
  
  
end
