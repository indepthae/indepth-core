Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "TaskManagement",:description => 'task_management'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('TaskManagement').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>170 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  collaboration_category = MenuLinkCategory.find_by_name("collaboration")
  MenuLink.create(:name=>'tasks_label',:target_controller=>'tasks',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'task-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>collaboration_category.id) unless MenuLink.exists?(:name=>'tasks_label')
end

if FedenaPlugin.plugin_installed?("fedena_data_palette")
  unless Palette.exists?(:name=>"tasks_due")
    p = FedenaDataPalette.create("tasks_due","Task","fedena_task","task-icon") do
      user_roles [:admin,:employee,:student] do
        with do
          all(:conditions=>["due_date = ? AND ((user_id = ?) OR (id IN (select task_id from task_assignees where assignee_id = ?)))",:cr_date,later(%Q{Authorization.current_user.id}),later(%Q{Authorization.current_user.id})],:limit=>:lim,:offset=>:off)
        end
      end
    end

    p.save
  end
end