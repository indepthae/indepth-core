sql="UPDATE assessment_scores s inner join exams e on s.exam_id is not null and e.id = s.exam_id inner join exam_groups eg on eg.id = e.exam_group_id set s.subject_id = e.subject_id,s.cce_exam_category_id=eg.cce_exam_category_id where s.id > 1"
ActiveRecord::Base.connection.execute(sql)
