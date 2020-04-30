Privilege.reset_column_information
Privilege.find_or_create_by_name :name => "OnlineExamControl",:description => "online_exam_control_privilege"
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('OnlineExamControl').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('academics').id, :priority=>325 )
end

unless defined?(MenuLink).nil?
  academics_category = MenuLinkCategory.find_by_name("academics")
  MenuLink.create(:name=>'online_exam_text',:target_controller=>'online_exam',:target_action=>'index',:higher_link_id=>MenuLink.find_by_name('examination').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'online_exam_text',:link_type=>'general')
  MenuLink.create(:name=>'online_exam_text',:target_controller=>'online_student_exam',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'examination-icon',:link_type=>'own',:user_type=>'student',:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'online_exam_text',:link_type=>'own')
  MenuLink.create(:name=>'evaluate_online_exam',:target_controller=>'online_exam',:target_action=>'evaluator_home',:higher_link_id=>MenuLink.find_by_name('examination').id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'evaluate_online_exam',:link_type=>'general')
end