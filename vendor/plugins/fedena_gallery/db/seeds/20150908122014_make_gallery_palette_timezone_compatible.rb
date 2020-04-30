if FedenaPlugin.plugin_installed?("fedena_data_palette")
  p = Palette.find_by_name("photos_added")
  if p.present?
    p.palette_queries.destroy_all


    p.instance_eval do
      user_roles [:admin,:photo_admin] do
        with do
          all(:conditions=>["created_at between ? and ?",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Employee')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Student')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.student_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  else
    p = FedenaDataPalette.create("photos_added","GalleryPhoto","fedena_gallery","galleries-icon") do
      user_roles [:admin,:photo_admin] do
        with do
          all(:conditions=>["created_at between ? and ?",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:employee] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Employee')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.employee_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND id IN (select gallery_photo_id from gallery_tags where member_id = ? and member_type = 'Student')",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.student_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end