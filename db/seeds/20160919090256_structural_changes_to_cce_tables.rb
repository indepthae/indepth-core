sql="UPDATE cce_reports cr inner join exams e on cr.exam_id = e.id inner join subjects s on s.id = e.subject_id inner join exam_groups eg on eg.id = e.exam_group_id set cr.subject_id = e.subject_id,cr.cce_exam_category_id=eg.cce_exam_category_id where cr.id > 1"
ActiveRecord::Base.connection.execute(sql)
