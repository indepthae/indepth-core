transport_report_menu = MenuLink.find_by_name('report', :conditions=>{:target_controller=>'transport',:target_action=>'vehicle_report',:icon_class=>nil,:link_type=>'general',:user_type=>nil})
transport_report_menu.update_attribute('target_action','reports') if transport_report_menu.present?