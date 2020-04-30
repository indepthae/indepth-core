p = Palette.find_by_name("leave_applications")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin,:hr_basics,:employee_attendance] do
    with do
      all(:conditions=>["DATE(created_at) = ? AND viewed_by_manager = 0",:cr_date],:limit=>:lim,:offset=>:off)
    end
  end
  user_roles [:employee] do
    with do
      all(:joins=>"inner JOIN employees on apply_leaves.employee_id = employees.id", :select=>"apply_leaves.*",:conditions=>["DATE(apply_leaves.created_at) = ? AND apply_leaves.viewed_by_manager = 0 AND employees.reporting_manager_id = ?",:cr_date,later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
    end
  end
end

p.save