
menu_link_present = MenuLink rescue false
unless menu_link_present == false
  administration_category = MenuLinkCategory.find_by_name("administration")
  MenuLink.create(:name=>'online_payment',:target_controller=>'online_payments',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'online-payment-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>administration_category.id) unless MenuLink.exists?(:name=>'online_payment')
end