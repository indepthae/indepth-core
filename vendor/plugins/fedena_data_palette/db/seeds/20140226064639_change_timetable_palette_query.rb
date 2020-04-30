p = Palette.find_by_name("timetable")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:manage_timetable,:timetable_view] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ?",:cr_date,:cr_date,:cr_date],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.employee_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:student] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:parent] do
    with do
      all(:joins=>"left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["timetable_entries.weekday_id = (DAYOFWEEK(?)-1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id})],:limit=>:lim,:offset=>:off)
    end
  end
end

p.save