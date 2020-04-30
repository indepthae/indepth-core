ActiveRecord::Base.connection.execute("delete dup.* from online_exam_score_details as dup inner join
  ( select min(id) as minId, online_exam_question_id, online_exam_option_id, online_exam_attendance_id from online_exam_score_details group by online_exam_question_id,
  online_exam_option_id, online_exam_attendance_id having count(*)>1 ) as save on
  save.online_exam_question_id=dup.online_exam_question_id and save.online_exam_option_id=dup.online_exam_option_id and
  save.online_exam_attendance_id=dup.online_exam_attendance_id and save.minId <> dup.id;")