class GradebookAttendanceEntryForm < Tableless
  
  column :batch_id, :integer
  column :linkable_type, :string
  column :linkable_id, :integer
  column :report_type, :string
  
  has_many :gradebook_attendances
  belongs_to :batch
  belongs_to :student
  
  accepts_nested_attributes_for :gradebook_attendances
 
  
  def build_attendance_form
    all_attendance = GradebookAttendance.all(:conditions=>["batch_id = ? and linkable_type = ? and linkable_id = ? and report_type = ?",batch_id,linkable_type,linkable_id,report_type]).to_a
    attendance = []
    batch.effective_students.each do |student|
      student_attendance = all_attendance.find{|obj| obj.student_id == student.s_id}
      attendance << if student_attendance.present?
        student_attendance.attributes = {
          :batch_id => batch_id,
          :student_id => student.s_id,
          :student_name => student.full_name,
          :student_roll_no => student.roll_number,
          :student_admission_no => student.admission_no
        }
        student_attendance
      else
        gradebook_attendances.build(:batch_id => batch_id,
          :student_id => student.s_id,
          :student_name => student.full_name,
          :student_roll_no => student.roll_number,
          :student_admission_no => student.admission_no)
      end
    end
    attendance
  end
  
  def save_attendance_entry(params)
    saved = false
    params.each_pair do |_,value|
      attendance = GradebookAttendance.find_or_initialize_by_batch_id_and_linkable_type_and_linkable_id_and_student_id_and_report_type(value)
      if attendance.new_record?
        next if value["total_working_days"].blank?
        attendance.save
        saved = true
      else
        saved = true
        if value["total_working_days"].blank? and value["total_working_days"]
          attendance.destroy()
        else
          attendance.update_attributes(:total_days_present=>value["total_days_present"],:total_working_days=>value["total_working_days"])
        end
      end
    end
    saved
  end
end
