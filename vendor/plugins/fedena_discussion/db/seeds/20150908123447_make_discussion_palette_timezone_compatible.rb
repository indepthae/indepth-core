if FedenaPlugin.plugin_installed?("fedena_data_palette")
  p = Palette.find_by_name("discussions")
  if p.present?
    p.palette_queries.destroy_all


    p.instance_eval do
      user_roles [:admin,:employee,:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND group_id IN (select group_id from group_members where user_id = ?)",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  else
    p = FedenaDataPalette.create("discussions","GroupPost","fedena_discussion","discussion-icon") do
      user_roles [:admin,:employee,:student] do
        with do
          all(:conditions=>["(created_at between ? and ?) AND group_id IN (select group_id from group_members where user_id = ?)",later(%Q{Palette.tzone_start_time(cr_date)}),later(%Q{Palette.tzone_end_time(cr_date)}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end