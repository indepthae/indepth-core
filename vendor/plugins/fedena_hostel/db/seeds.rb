Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "HostelAdmin",:description => "hostel_admin_privilege"
FinanceTransactionCategory.find_or_create_by_name(:name => 'Hostel', :description => ' ', :is_income => true)
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('HostelAdmin').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>140 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")

  MenuLink.create(:name=>'hostel_text',:target_controller=>'hostels',:target_action=>'hostel_dashboard',:higher_link_id=>nil,:icon_class=>'hostel-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'hostel_text')

  higher_link=MenuLink.find_by_name_and_higher_link_id('hostel_text',nil)

  MenuLink.create(:name=>'hostel_text',:target_controller=>'hostels',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'hostel_text',:higher_link_id=>higher_link.id)
  MenuLink.create(:name=>'rooms',:target_controller=>'room_details',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'rooms')
  MenuLink.create(:name=>'room_allocation',:target_controller=>'room_allocate',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'room_allocation')
  MenuLink.create(:name=>'fee_collection',:target_controller=>'hostel_fee',:target_action=>'hostel_fee_collection',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'fee_collection')
  MenuLink.create(:name=>'hostel_fee_pay',:target_controller=>'hostel_fee',:target_action=>'hostel_fee_pay',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'hostel_fee_pay')
  MenuLink.create(:name=>'hostel_fee_defaulters',:target_controller=>'hostel_fee',:target_action=>'hostel_fee_defaulters',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'hostel_fee_defaulters')
  MenuLink.create(:name=>'pay_student_hostel_fee',:target_controller=>'hostel_fee',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'pay_student_hostel_fee')
  MenuLink.create(:name=>'report',:target_controller=>'hostels',:target_action=>'room_availability_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'report',:higher_link_id=>higher_link.id)
end
