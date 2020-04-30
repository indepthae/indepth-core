p = Palette.find_by_name("leave_applications")
if p.present?
  p.palette_queries.destroy_all

  p.instance_eval do
    user_roles [:admin,:hr_basics,:employee_attendance] do
      with do
        all(:conditions=>["(created_at between ? and ?) AND viewed_by_manager = 0",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
      end
    end
    user_roles [:employee] do
      with do
        all(:joins=>"inner JOIN employees on apply_leaves.employee_id = employees.id", :select=>"apply_leaves.*",:conditions=>["(apply_leaves.created_at between ? and ?) AND apply_leaves.viewed_by_manager = 0 AND employees.reporting_manager_id = ?",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
      end
    end
  end

  p.save

end

p = Palette.find_by_name("sms_sent")
if p.present?
  p.palette_queries.destroy_all

  p.instance_eval do
    user_roles [:admin,:sms_management] do
      with do
        all(:conditions=>["created_at between ? and ?",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
      end
    end
  end

  p.save

end

p = Palette.find_by_name("news")
if p.present?
  p.palette_queries.destroy_all

  p.instance_eval do
    user_roles [:admin,:employee,:student,:parent] do
      with do
        all(:conditions=>["created_at between ? and ?",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
      end
    end
  end

  p.save

end

p = Palette.find_by_name("removed_employees")
if p.present?
  p.palette_queries.destroy_all

  p.instance_eval do
    user_roles [:admin, :hr_basics, :employee_search] do
      with do
        all(:conditions=>["created_at between ? and ?", later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
      end
    end
  end

  p.save

end