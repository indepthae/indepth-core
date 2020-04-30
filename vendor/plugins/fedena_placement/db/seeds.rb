Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "PlacementActivities",:description => 'placement_activities_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('PlacementActivities').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>180 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  academics_category = MenuLinkCategory.find_by_name("academics")
  MenuLink.create(:name=>'placement',:target_controller=>'placementevents',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'placement-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'placement')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"placements")
    p = FedenaDataPalette.create("placements","Placementevent","fedena_placement","placement-icon") do
      user_roles [:admin,:placement_activities] do
        with do
          all(:conditions=>["date = ? AND is_active = 1",:cr_date],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:student] do
        with do
          all(:conditions=>["date = ? AND is_active = 1 AND id IN (select placementevent_id from placement_registrations where student_id = ? and is_approved = 1)",:cr_date,later(%Q{Authorization.current_user.student_record.id})],:limit=>:lim,:offset=>:off)
        end
      end
      user_roles [:parent] do
        with do
          all(:conditions=>["date = ? AND is_active = 1 AND id IN (select placementevent_id from placement_registrations where student_id = ? and is_approved = 1)",:cr_date,later(%Q{Authorization.current_user.guardian_entry.current_ward_id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end
