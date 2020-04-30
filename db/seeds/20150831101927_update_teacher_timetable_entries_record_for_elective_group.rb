unless (MultiSchool rescue false)
  TimetableEntry.find_in_batches(:include => [:subject => {:elective_group => :subjects}], :batch_size => 500, :joins => "LEFT OUTER JOIN subjects s on s.id = timetable_entries.subject_id LEFT OUTER JOIN elective_groups eg on eg.id = s.elective_group_id") do |timetable_entries|
      timetable_entries.each do |tte|
        if tte.subject_id.present? and tte.subject.present? and tte.subject.elective_group_id.present?
          subject = tte.subject
          subjects = subject.elective_group.subjects
          tte_emp_ids = subjects.map{ |x| x.employees.map(&:id) }.flatten
          tte.employee_ids = tte_emp_ids if tte_emp_ids.present?
        end
      end
  end
else
  School.all.each do |school|
    MultiSchool.current_school = school
    TimetableEntry.find_in_batches(:include => [:subject => {:elective_group => :subjects}], :batch_size => 500, :joins => "LEFT OUTER JOIN subjects s on s.id = timetable_entries.subject_id LEFT OUTER JOIN elective_groups eg on eg.id = s.elective_group_id") do |timetable_entries|
      timetable_entries.each do |tte|
        if tte.subject_id.present? and tte.subject.present? and tte.subject.elective_group_id.present?
          subject = tte.subject
          subjects = subject.elective_group.subjects
          tte_emp_ids = subjects.map{ |x| x.employees.map(&:id) }.flatten
          tte.employee_ids = tte_emp_ids if tte_emp_ids.present?
        end
      end
    end
  end
end
