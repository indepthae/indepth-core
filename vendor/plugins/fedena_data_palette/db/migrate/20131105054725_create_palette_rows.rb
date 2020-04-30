class CreatePaletteRows < ActiveRecord::Migration
  def self.up
    unless Palette.exists?(:name=>"examinations")
      p = FedenaDataPalette.create("examinations","Exam",nil,"examination-icon") do
        user_roles [:admin,:examination_control] do
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
    end

    unless Palette.exists?(:name=>"leave_applications")
      p = FedenaDataPalette.create("leave_applications","ApplyLeave",nil,"leaves-icon") do
        user_roles [:admin,:hr_basics,:employee_attendance] do
          with do
            all(:conditions=>["DATE(created_at) = ? AND (approved = 0 OR approved is NULL)",:cr_date],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:joins=>"inner JOIN employees on apply_leaves.employee_id = employees.id", :select=>"apply_leaves.*",:conditions=>["DATE(apply_leaves.created_at) = ? AND (apply_leaves.approved = 0 OR apply_leaves.approved is NULL) AND employees.reporting_manager_id = ?",:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"employees_on_leave")
      p = FedenaDataPalette.create("employees_on_leave","EmployeeAttendance",nil,"hr-icon") do
        user_roles [:admin, :hr_basics, :employee_attendance] do
          with do
            all(:conditions=>{:attendance_date=>:cr_date},:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:joins=>"inner JOIN employees on employee_attendances.employee_id = employees.id", :select=>"employee_attendances.*",:conditions=>["employee_attendances.attendance_date = ? AND employees.reporting_manager_id = ?",:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    #unless Palette.exists?(:name=>"employees_on_leave")
    #  p = FedenaDataPalette.create("employees_on_leave", "ApplyLeave",nil,"hr-icon") do
    #    user_roles [:admin,:hr_basics,:employee_attendance] do
    #      with do
    #        all(:conditions=>["start_date <= ? AND end_date >= ? AND approved = 1",:cr_date,:cr_date],:limit=>:lim,:offset=>:off)
    #      end
    #    end
    #    user_roles [:employee] do
    #      with do
    #        all(:conditions=>["start_date <= ? AND end_date >= ? AND approved = 1 AND employee_id IN (select id from employees where reporting_manager_id = ?)",:cr_date,:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
    #      end
    #    end
    #  end
    #
    #  p.save
    #end

    unless Palette.exists?(:name=>"sms_sent")
      p = FedenaDataPalette.create("sms_sent","SmsLog",nil,"sms-icon") do
        user_roles [:admin,:sms_management] do
          with do
            all(:conditions=>["DATE(created_at) = ?",:cr_date],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"finance")
      p = FedenaDataPalette.create("finance","FinanceTransaction",nil,"finance-icon") do
        user_roles [:admin,:finance_control] do
          with do
            all(:conditions=>["transaction_date = ?",:cr_date],:limit=>1)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"timetable")
      p = FedenaDataPalette.create("timetable","TimetableEntry",nil,"timetable-icon") do
        user_roles [:admin,:manage_timetable,:timetable_view] do
          with do
            all(:joins=>"left JOIN weekdays on timetable_entries.weekday_id = weekdays.id left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["weekdays.day_of_week = (WEEKDAY(?)+1) AND timetables.start_date <= ? and timetables.end_date >= ?",:cr_date,:cr_date,:cr_date],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:joins=>"left JOIN weekdays on timetable_entries.weekday_id = weekdays.id left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["weekdays.day_of_week = (WEEKDAY(?)+1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.employee_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:student] do
          with do
            all(:joins=>"left JOIN weekdays on timetable_entries.weekday_id = weekdays.id left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["weekdays.day_of_week = (WEEKDAY(?)+1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:parent] do
          with do
            all(:joins=>"left JOIN weekdays on timetable_entries.weekday_id = weekdays.id left JOIN timetables on timetable_entries.timetable_id = timetables.id",:select=>"timetable_entries.*",:conditions=>["weekdays.day_of_week = (WEEKDAY(?)+1) AND timetables.start_date <= ? and timetables.end_date >= ? AND timetable_entries.batch_id = ?",:cr_date,:cr_date,:cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id})],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"birthdays")
      p = FedenaDataPalette.create("birthdays","User",nil,"birthday-icon") do
        user_roles [:admin,:employee,:student] do
          with do
            all(:joins=>"left JOIN students on users.id = students.user_id left JOIN employees on users.id = employees.user_id",:select=>"users.*",:conditions=>["DATE_FORMAT(students.date_of_birth,'%m-%d') = DATE_FORMAT(?,'%m-%d') OR DATE_FORMAT(employees.date_of_birth,'%m-%d') = DATE_FORMAT(?,'%m-%d')",:cr_date,:cr_date],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"news")
      p = FedenaDataPalette.create("news","News",nil,"news-icon") do
        user_roles [:admin,:employee,:student,:parent] do
          with do
            all(:conditions=>["DATE(created_at) = ?",:cr_date],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"fees_due")
      p = FedenaDataPalette.create("fees_due","Event",nil,"finance-icon") do
        user_roles [:admin,:finance_control] do
          with do
            all(:conditions=>["(? BETWEEN DATE(start_date) AND DATE(end_date)) AND is_due = 1 AND origin_type <> 'BookMovement'", :cr_date],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:student] do
          with do
            all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((id IN (select event_id from batch_events where batch_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.student_record.batch_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:parent] do
          with do
            all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((id IN (select event_id from batch_events where batch_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id}),later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:conditions=>["is_due = 1 AND origin_type <> 'BookMovement' AND (? BETWEEN DATE(start_date) AND DATE(end_date)) AND ((is_common = 1) OR (id IN (select event_id from employee_department_events where employee_department_id = ?)) OR (id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.employee_record.employee_department_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
      end
      p.save
    end

    unless Palette.exists?(:name=>"events")
      p = FedenaDataPalette.create("events","Event",nil,"event-icon") do
        user_roles [:admin,:event_management] do
          with do
            all(:select=>"events.*,exam_groups.is_published",:joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam' LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id",:group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",:conditions=>["? BETWEEN DATE(events.start_date) AND DATE(events.end_date)", :cr_date],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:student] do
          with do
            all(:select=>"events.*,exam_groups.is_published",:joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam' LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id",:group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",:conditions=>["(? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND ((events.is_common = 1) OR (events.id IN (select event_id from batch_events where batch_id = ?)) OR (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.student_record.batch_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:parent] do
          with do
            all(:select=>"events.*,exam_groups.is_published",:joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam' LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id",:group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",:conditions=>["(? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND ((events.is_common = 1) OR (events.id IN (select event_id from batch_events where batch_id = ?)) OR (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward.batch_id}),later(%Q{Authorization.current_user.guardian_entry.current_ward.user_id})],:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:select=>"events.*,exam_groups.is_published",:joins=>"LEFT OUTER JOIN exams on exams.id = events.origin_id AND events.origin_type='Exam' LEFT OUTER JOIN exam_groups on exam_groups.id = exams.exam_group_id",:group=>"events.id having exam_groups.is_published=1 or exam_groups.is_published is NULL",:conditions=>["(? BETWEEN DATE(events.start_date) AND DATE(events.end_date)) AND ((events.is_common = 1) OR (events.id IN (select event_id from employee_department_events where employee_department_id = ?)) OR (events.id IN(select event_id from user_events where user_id = ?)))", :cr_date,later(%Q{Authorization.current_user.employee_record.employee_department_id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"admitted_students")
      p = FedenaDataPalette.create("admitted_students","Student",nil,"student-icon") do
        user_roles [:admin, :admission, :students_control, :student_view] do
          with do
            all(:conditions=>{:admission_date=>:cr_date},:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"relieved_students")
      p = FedenaDataPalette.create("relieved_students","ArchivedStudent",nil,"student-icon") do
        user_roles [:admin, :admission, :students_control, :student_view] do
          with do
            all(:conditions=>["DATE(created_at) = ?", :cr_date],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"admitted_employees")
      p = FedenaDataPalette.create("admitted_employees","Employee",nil,"hr-icon") do
        user_roles [:admin, :hr_basics, :employee_search] do
          with do
            all(:conditions=>{:joining_date=>:cr_date},:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end

    unless Palette.exists?(:name=>"removed_employees")
      p = FedenaDataPalette.create("removed_employees","ArchivedEmployee",nil,"hr-icon") do
        user_roles [:admin, :hr_basics, :employee_search] do
          with do
            all(:conditions=>["DATE(created_at) = ?", :cr_date],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end



    unless Palette.exists?(:name=>"absent_students")
      p = FedenaDataPalette.create("absent_students","Attendance",nil,"student-icon") do
        user_roles [:admin, :student_attendance_register, :student_attendance_view] do
          with do
            all(:conditions=>{:month_date=>:cr_date},:limit=>:lim,:offset=>:off)
          end
        end
        user_roles [:employee] do
          with do
            all(:joins=>"inner JOIN batches on attendances.batch_id = batches.id",:select=>"attendances.*",:conditions=>["attendances.month_date = ? AND find_in_set (?,batches.employee_id)",:cr_date,later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
          end
        end
      end

      p.save
    end


  end

  def self.down
    Palette.destroy_all
  end
end
