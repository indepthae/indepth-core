p = Palette.find_by_name("examinations")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:examination_control,:enter_results] do
    with do
      all(:joins=>"inner JOIN exam_groups on exams.exam_group_id=exam_groups.id", :select=>"exams.*",:conditions=>["DATE(exams.start_time) = ? AND exam_groups.is_published=true",:cr_date],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:joins=>"inner JOIN exam_groups on exams.exam_group_id=exam_groups.id", :select=>"exams.*",:conditions=>["DATE(exams.start_time) = ? AND exam_groups.is_published=true AND ((exams.subject_id IN (?)) OR (exam_groups.batch_id IN (select id from batches where find_in_set (?,employee_id))))",:cr_date,later(%Q{Authorization.current_user.employee_record.subjects.collect(&:id)}),later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:student] do
    with do
      all(:joins=>"inner JOIN exam_groups on exams.exam_group_id=exam_groups.id", :select=>"exams.*",:conditions=>["DATE(exams.start_time) = ? AND exam_groups.is_published=true AND exam_groups.batch_id = ?",:cr_date,later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:parent] do
    with do
      all(:joins=>"inner JOIN exam_groups on exams.exam_group_id=exam_groups.id", :select=>"exams.*",:conditions=>["DATE(exams.start_time) = ? AND exam_groups.is_published=true AND exam_groups.batch_id = ?",:cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id})],:limit=>:lim,:offset=>:off)
    end
  end
end

p.save