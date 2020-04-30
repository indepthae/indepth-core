FinanceTransactionCategory.find_or_create_by_name(:name => 'Transport', :description => ' ', :is_income => true)
Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "TransportAdmin",:description => 'transport_admin_privilege'
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('TransportAdmin').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>130 )
end
menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")

  MenuLink.create(:name=>'transport_label',:target_controller=>'transport',:target_action=>'dash_board',:higher_link_id=>nil,:icon_class=>'transport-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_label',:higher_link_id=>nil)

  higher_link=MenuLink.find_by_name_and_higher_link_id('transport_label',nil)

  MenuLink.create(:name=>'transport.set_routes',:target_controller=>'routes',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport.set_routes')
  MenuLink.create(:name=>'vehicles_text',:target_controller=>'vehicles',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'vehicles_text')
  MenuLink.create(:name=>'assign_transport',:target_controller=>'transport',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'assign_transport',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'transport_fee_text',:target_controller=>'transport_fee',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_fee_text')
  MenuLink.create(:name=>'report',:target_controller=>'transport',:target_action=>'reports',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'report',:higher_link_id=>higher_link.id)
  
  #new links
  MenuLink.create(:name=>'settings',:target_controller=>'transport',:target_action=>'configurations',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'settings',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'stops',:target_controller=>'vehicle_stops',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'stops',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'vehicle_maintenance',:target_controller=>'vehicle_maintenances',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'vehicle_maintenance',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'manage_driver_and_attendant',:target_controller=>'transport_employees',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'manage_driver_and_attendant',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'transport_attendance_label',:target_controller=>'transport_attendance',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_attendance_label',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'transport_import_label',:target_controller=>'transport_imports',:target_action=>'new',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'transport_import_label',:higher_link_id=>higher_link.id)
 
  report_link = MenuLink.find_by_name_and_higher_link_id('report', higher_link.id)
  report_link.update_attributes(:target_controller=>'transport_reports',:target_action=>'index') if report_link.present?
  
  assign_link = MenuLink.find_by_name_and_higher_link_id('transport_label', higher_link.id)
  assign_link.destroy if assign_link.present?
end