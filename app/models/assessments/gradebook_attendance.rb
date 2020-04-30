class GradebookAttendance < ActiveRecord::Base
  attr_accessor :gradebook_attendance_entry_form_ids, :student_name, :student_roll_no, :student_admission_no
  belongs_to :linkable, :polymorphic => true
  belongs_to :student
  belongs_to :batch
  
  def validate
    if total_working_days.present? and total_days_present.present? and total_working_days < total_days_present
      errors.add(:total_days_present,:attendance_count)
    end
    if total_days_present.present? and total_working_days.nil?
      errors.add(:total_working_days,:attendance_count)
    end
  end
  
  def self.fetch_exams(batch)
    arr = []
    list = []
    hsh = batch.assessment_groups.all(:order=>:name,:conditions=>["type=? and is_single_mark_entry = ? and consider_attendance = ?","SubjectAssessmentGroup",true,true]).group_by(&:parent_id)
    terms = AssessmentTerm.find(:all, :conditions=>["id in (?)",hsh.keys])
    hsh.each_pair{|key,val| arr = [terms.find{|t| t.id == key.to_i}.name,val.map{|v| [v.name,v.id]}]; list.push(arr)} if hsh.present?
    list
  end
  
end