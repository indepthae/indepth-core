if FedenaPlugin.plugin_installed?("fedena_data_palette")
  p = Palette.find_by_name("polls")
  if p.present?
    p.palette_queries.destroy_all


    p.instance_eval do
      user_roles [:admin,:poll_admin] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'EmployeeDepartment')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.employee_record.employee_department_id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'Batch')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  else
    p = FedenaDataPalette.create("polls","PollQuestion","fedena_poll","poll-icon") do
      user_roles [:admin,:poll_admin] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'EmployeeDepartment')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.employee_record.employee_department_id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND is_active = 1 AND id IN (select poll_question_id from poll_members where member_id = ? and member_type = 'Batch')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.student_record.batch_id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end