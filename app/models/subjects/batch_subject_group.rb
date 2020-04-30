class BatchSubjectGroup < ActiveRecord::Base
  belongs_to :subject_group
  belongs_to :batch
  has_many :elective_groups
  has_many :subjects
  has_many :converted_assessment_marks, :as => :markable

  include Gradebook::Rounding

  def round_off (value)
    gb_round_off(value)
  end
  
  def dependency_present?
    subjects.active.present? or elective_groups.active.present?
  end
  
  def sorted_components
    components = []
    components += self.elective_groups.select{|s| !s.is_deleted }
    components += self.subjects.select{|s| s.elective_group_id.nil?  and !s.is_deleted }
    
    components.sort_by {|child| [child.priority ? 0 : 1,child.priority || 0]}
  end
  
  def check_and_destroy
    if dependency_present?
      return false
    else
      update_attribute(:is_deleted, true)
    end
  end
  
  def calculate_group_mark(marks, group, grades = [])
    unless group.grade_type?
      grade_set = group.grade_set
      mark = round_off(send("calculate_#{self.formula}", marks, group))
      percentage = ((mark.to_f/group.maximum_marks.to_f)*100)
      mark_grade = grade_set.select_grade_for(grades, percentage) if grade_set  
      {:mark => mark, :grade => mark_grade.try(:name), :credit_points => mark_grade.try(:credit_points)}
    else
      {}
    end
  end
  
  def calculate_sum(marks, group)
    ms = marks.map{|id, values| values['mark'].to_f}
    course = self.batch.course
    max_mark = 0
    marks.each_pair{|id, value| max_mark += group.maximum_marks_with_code(value['subject_code'],course)} #Calculating total mark of subjects
    ms.sum.round(2)/max_mark * group.maximum_marks if group.maximum_marks.present?
  end
  
  def calculate_average(marks, group)
    (marks.map{|id, values| values['mark'].to_f}.sum / marks.length).to_f.round(2)
  end
  
  def calculate_bestof(marks, group)
    converted_marks = marks.map{|id, values| values['mark'].to_f}
    converted_marks.max
  end
  
  def is_activity?
    false #Fallback method for using report generation methods
  end
  
  def parent_name_and_type(subject = nil)
    [batch.name, 'Batch', batch_id]
  end
  
end