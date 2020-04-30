#=====Fetch Online Exam Attendance that donot have batch_id and update it=====
School.active.each do |school|
  MultiSchool.current_school=school
  exam_attendance = OnlineExamAttendance.all.select{|i| i.batch_id.nil?}
  if exam_attendance.present?
    exam_group = OnlineExamGroup.all
    batch_stud = BatchStudent.all
    batch_stud.reject! { |b| b.created_at.nil? }
    exam_attendance.each do |e_a|
      student = Student.find_by_id(e_a.student_id)
      batch_list = exam_group.find_by_id(e_a.online_exam_group_id).batches.map{|i| i.id}
      if student.present?
        batch_student_val = batch_stud.select{|s| (s.student_id == e_a.student_id && e_a.start_time < s.created_at)}.sort_by(&:id)       
        unless batch_student_val.present?
          e_a.update_attributes(:batch_id => student.batch_id) if batch_list.include?(student.batch_id)
        else
          e_a.update_attributes(:batch_id=>batch_student_val.first.batch_id) if batch_list.include?(batch_student_val.first.batch_id)
        end
      end
    end
  end
end