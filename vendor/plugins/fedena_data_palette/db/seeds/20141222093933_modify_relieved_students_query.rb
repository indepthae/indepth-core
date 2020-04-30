p = Palette.find_by_name("relieved_students")
if p.present?
  p.palette_queries.destroy_all
end


p.instance_eval do
  user_roles [:admin, :admission, :students_control, :student_view] do
    with do
      all(:conditions=>["DATE(date_of_leaving) = ?", :cr_date],:limit=>:lim,:offset=>:off)
    end
  end
end

p.save