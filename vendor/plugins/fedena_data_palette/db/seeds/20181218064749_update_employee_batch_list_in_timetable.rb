# ===== Modified :conditions by including active batches for Admin and Employee ======
p = Palette.find_by_name("timetable")
if p.present?
  p.palette_queries.destroy_all
end

p.instance_eval do
  user_roles [:admin,:manage_timetable,:timetable_view] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id left JOIN class_timings on timetable_entries.class_timing_id = class_timings.id left JOIN batches on batches.id=timetable_entries.batch_id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND batches.is_active=? AND batches.is_deleted=?",:cr_date,:cr_date,:cr_date,true,false],:limit=>:lim,:offset=>:off,:order=>"class_timings.start_time")
    end
  end
  user_roles [:employee] do
    with do
      all(:joins=>"left JOIN timetables t on timetable_entries.timetable_id = t.id left JOIN class_timings ct on timetable_entries.class_timing_id = ct.id left JOIN teacher_timetable_entries tte on tte.timetable_entry_id = timetable_entries.id left JOIN batches on batches.id=timetable_entries.batch_id", :select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND t.start_date <= ? and t.end_date >= ? AND tte.employee_id = ? AND batches.is_active=? AND batches.is_deleted=?", :cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.employee_record.id}),true,false],:limit=>:lim,:offset=>:off,:order=>"ct.start_time")
    end
  end
  user_roles [:student] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id left JOIN class_timings on timetable_entries.class_timing_id = class_timings.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off,:order=>"class_timings.start_time")
    end
  end
  user_roles [:parent] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id left JOIN class_timings on timetable_entries.class_timing_id = class_timings.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id})],:limit=>:lim,:offset=>:off,:order=>"class_timings.start_time")
    end
  end
end

p.save