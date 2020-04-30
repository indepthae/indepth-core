timetable_entry_update_sql = "update timetable_entries te left outer join subjects s on s.id=te.subject_id
 set te.entry_id=ifnull(s.elective_group_id,s.id), te.entry_type=if(s.elective_group_id is null, 'Subject', 'ElectiveGroup') where subject_id is not null;"
teacher_timetable_entry_insert_sql = "INSERT INTO teacher_timetable_entries (`employee_id`,`timetable_entry_id`)
 SELECT es.employee_id AS es_eid, te.id AS te_id FROM timetable_entries te
 LEFT OUTER JOIN subjects s ON s.id = te.subject_id
 LEFT OUTER JOIN employees_subjects es ON s.id = es.subject_id
 WHERE es.employee_id IS NOT NULL and s.elective_group_id is not null
UNION
 SELECT te.employee_id AS es_eid, te.id AS te_id FROM timetable_entries te
 LEFT OUTER JOIN subjects s ON s.id = te.subject_id
 WHERE te.employee_id IS NOT NULL and s.elective_group_id is null;"
subject_leave_teachers_insert_sql = "INSERT INTO subject_leaves_teachers (`subject_leave_id`, `employee_id`)
SELECT sl.id AS sl_id, sl.employee_id AS sl_eid
FROM subject_leaves sl LEFT OUTER JOIN employees e on sl.employee_id = e.id
WHERE sl.employee_id IS NOT NULL and e.id is not null;"
RecordUpdate.connection.execute(timetable_entry_update_sql)
RecordUpdate.connection.execute(teacher_timetable_entry_insert_sql)
RecordUpdate.connection.execute(subject_leave_teachers_insert_sql)