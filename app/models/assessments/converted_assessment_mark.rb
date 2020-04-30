class ConvertedAssessmentMark < ActiveRecord::Base
  
  serialize :actual_mark, Hash
  
  belongs_to :markable, :polymorphic => true
  belongs_to :assessment_group_batch
  belongs_to :assessment_group
  belongs_to :student
  
  include CsvExportMod
  
  def mark_with_grade
    if mark.present? and (!self.assessment_group.hide_marks or self.assessment_group.scoring_type != 3 )
      "#{mark.to_f.round(2)} #{overrided_max_mark}#{grade.present? ? " &#x200E;(#{grade})&#x200E;" : ""}"
    else
      grade
    end 
  end
  
  def get_grade(markable)
    if markable.is_a? Subject or markable.is_a? BatchSubjectGroup
      grade
    else
      skill_grade(markable.id)
    end
  end
  
  def get_mark(markable)
    if markable.is_a? Subject or markable.is_a? BatchSubjectGroup
       mark.present? ? mark.to_f.round(2) : ''
    else
      skill_mark(markable.id)
    end
  end
  
  def get_credit_point(markable)
    if markable.is_a? Subject or markable.is_a? BatchSubjectGroup
      credit_points
    else
      skill_credit_points(markable.id)
    end
  end
  
  def skill_mark_with_grade(skill_id)
    if actual_mark.present? and actual_mark.has_key?(skill_id)
      mark = actual_mark[skill_id][:mark]
      grade = actual_mark[skill_id][:grade]
      if mark.present? and !self.assessment_group.hide_marks
        "#{mark.to_f.round(2)}#{grade.present? ? "&#x200E;(#{grade})&#x200E;" : ""}"
      else
        grade
      end
    else
      '-'
    end
  end
  
  def skill_mark(skill_id)
    (actual_mark.present? and actual_mark.has_key?(skill_id)) ? actual_mark[skill_id][:mark] : ''
  end
  
  def skill_grade(skill_id)
    (actual_mark.present? and actual_mark.has_key?(skill_id)) ? actual_mark[skill_id][:grade] : ''
  end
  
  def skill_credit_points(skill_id)
    (actual_mark.present? and actual_mark.has_key?(skill_id)) ? actual_mark[skill_id][:credit_points] : ''
  end
  
  def mark_and_grades
    if mark.present?
      ind_marks = "#{mark.to_f.round(2)} #{overrided_max_mark}"
      return ind_marks,grade
    else  
      grade
    end
  end
  
  def mark_with_omm
    if mark.present?
      "#{mark.to_f}#{overrided_max_mark}"
    else
      '-'
    end
    
  end
  
  def overrided_max_mark
    if self.markable_type != "Activity" and self.markable_type != "BatchSubjectGroup"
      self.assessment_group.overrided_mark(self.markable,self.assessment_group_batch.batch.course_id)
    else
      ""
    end
  end
  
  def maximum_mark(markable, course)
    #CheckNp1
    if markable.is_a? Subject
      self.assessment_group.maximum_marks_for(markable, course)
    elsif !markable.is_a? BatchSubjectGroup
      markable.maximum_marks.to_f
    elsif markable.is_a? BatchSubjectGroup
      self.assessment_group_batch.assessment_group.maximum_marks.to_f
    end
  end
  
  def minimum_mark(markable)
    if markable.is_a? Subject
      self.assessment_group.minimum_marks.to_f
    elsif !markable.is_a? BatchSubjectGroup
      markable.minimum_marks
    elsif markable.is_a? BatchSubjectGroup
      self.assessment_group_batch.assessment_group.minimum_marks.to_f
    end
  end
  
  def self.gradebook_subject_report(params)
    gradebook_subject_report_data params
  end
  
  def self.gradebook_consolidated_reports(params)
    gradebook_consolidated_reports_data params
  end
  
  def self.fetch_subject_wise_report(data_hash)
    students = fetch_gradebook_students(data_hash) 
    student_ids = students.collect(&:s_id)
    report = ConvertedAssessmentMark.all(:joins=>[:assessment_group],
      :select=>"mark,grade,markable_id,actual_mark,is_single_mark_entry as subject_exam, type as ag_type,student_id",
      :conditions=>["student_id in (?) and markable_id = ? and assessment_group_id= ?",student_ids,data_hash[:subject],data_hash[:exam]])
    report
  end
  
  def self.fetch_gradebook_students(data_hash)
    subject = Subject.find data_hash[:subject]
    conditions = "true"
    conditions += " and gender = '#{data_hash[:gender]}'" if data_hash[:gender].present?
    conditions += " and student_category_id = #{data_hash[:student_category]}" if data_hash[:student_category].present? and data_hash[:student_category] != 'none'
    conditions += " and student_category_id is null" if data_hash[:student_category] == 'none'
    if subject.elective_group_id?
      s_ids = subject.students_subjects.collect(&:student_id)
      if subject.batch.is_active?
        conditions += " and batch_id = #{subject.batch_id}" 
        Student.find_all_by_id(s_ids, :order => Student.sort_order,:conditions=>conditions)
      else
        conditions += " and students_subjects.subject_id = #{subject.id} and students_subjects.batch_id = #{subject.batch_id}"
        Student.all(:joins=>[:batch_students,:students_subjects],:conditions=>conditions,
        :order=>"#{Student.sort_order}",:group=>"students.id") + 
        ArchivedStudent.all(:joins => :students_subjects, :conditions =>conditions)
      end
    else
      if subject.batch.is_active?
        subject.batch.students.all(:order => Student.sort_order,:conditions=>conditions)
      else
        sql = <<-SQL
       select s.id id,CONCAT_WS('',s.first_name,' ',s.last_name) full_name,s.admission_no,s.first_name,s.last_name,
        bs.roll_number roll_number from students s inner join batch_students bs on bs.student_id=s.id where bs.batch_id=#{subject.batch.id} UNION ALL select ars.former_id id,
        CONCAT_WS('',ars.first_name,' ',ars.last_name) full_name,ars.admission_no,ars.first_name,ars.last_name,ars.roll_number roll_number from archived_students ars where ars.batch_id=#{subject.batch.id}
        UNION ALL select ars1.former_id id,CONCAT_WS('',ars1.first_name,' ',ars1.last_name) full_name,ars1.admission_no,ars1.first_name,ars1.last_name,
        bs.roll_number roll_number from archived_students ars1 inner join batch_students bs on bs.student_id=ars1.former_id where bs.batch_id=#{subject.batch.id} 

        SQL
        
        student_ids = BatchStudent.find_by_sql(sql).collect(&:id)
        former_ids = ArchivedStudent.all(:conditions => {:batch_id => subject.batch.id}).collect(&:former_id)
        Student.find_all_by_id(student_ids,:conditions=>conditions) + ArchivedStudent.find_all_by_former_id(student_ids+former_ids,:conditions=>conditions)
        #      Student.all(:joins => :batch_students, :conditions=>{:batch_students =>{:batch_id => @batch.id} }, :order => Student.sort_order) 
      end
    end
  end
 
  
  def self.get_derived_subjects(subject_id)
      ConvertedAssessmentMark.find(:all, 
        :group => 'assessment_group_id', 
        :joins =>:assessment_group,
        :select => "assessment_groups.name,assessment_groups.id,parent_id,assessment_groups.type as ag_type,assessment_groups.is_single_mark_entry", 
        :conditions=>["markable_type = ? and markable_id = ? and type = ?",'Subject',subject_id,'DerivedAssessmentGroup'],:order=>"assessment_groups.id")
  end
  
end
