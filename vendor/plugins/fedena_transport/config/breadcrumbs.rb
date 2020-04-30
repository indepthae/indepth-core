Gretel::Crumbs.layout do
  crumb :transport_dash_board do
    link I18n.t('transport_text'), {:controller=>"transport", :action=>"dash_board"}
  end
  crumb :routes_index do
    link I18n.t('routes.route_details'), {:controller=>"routes", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :routes_new do
    link I18n.t('routes.add_new_route'), {:controller=>"routes", :action=>"new"}
    parent :routes_index
  end
  crumb :routes_create do
    link I18n.t('routes.add_new_route'), {:controller=>"routes", :action=>"new"}
    parent :routes_index
  end
  crumb :routes_show do |route|
    link route.name, {:controller=>"routes", :action=>"show",:id=>route.id}
    parent :routes_index
  end
  crumb :routes_edit do |route|
    link "#{I18n.t('edit_text')} - #{route.name_was}", {:controller=>"routes", :action=>"edit", :id => route.id}
    parent :routes_index
  end
  crumb :vehicles_index do
    link I18n.t('transport.vehicles'), {:controller=>"vehicles", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :vehicles_new do
    link I18n.t('vehicles.add_new_vehicle'), {:controller=>"vehicles", :action=>"new"}
    parent :vehicles_index
  end
  crumb :vehicles_show do |vehicle|
    link vehicle.vehicle_no, {:controller=>"vehicles", :action=>"show",:id=>vehicle.id}
    parent :vehicles_index
  end
  crumb :vehicles_create do
    link I18n.t('vehicles.add_new_vehicle'), {:controller=>"vehicles", :action=>"new"}
    parent :vehicles_index
  end
  crumb :vehicles_edit do |vehicle|
    link "#{I18n.t('edit_text')} - #{vehicle.vehicle_no_was}", {:controller=>"vehicles", :action=>"edit", :id => vehicle.id}
    parent :vehicles_index
  end
  crumb :transport_index do
    link I18n.t('assign_transport'), {:controller=>"transport", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :transport_transport_details do
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"transport_details"}
    parent :transport_dash_board
  end
  crumb :transport_edit_transport do |transport|
    link transport.receiver.full_name, {:controller=>"transport", :action=>"edit_transport", :id => transport.id}
    parent :vehicles_show, transport.vehicle
  end
  crumb :transport_add_transport do |user|
    link user.full_name, {:controller=>"transport", :action=>"add_transport", :id => user.id, :user => "employee"}
    parent :transport_index
  end
  crumb :transport_vehicle_report do
    link I18n.t('transport.vehicle_details'), {:controller=>"transport", :action=>"vehicle_report"}
    parent :transport_reports
  end
  crumb :transport_single_vehicle_details do |vehicle|
    link vehicle.vehicle_no, {:controller=>"transport", :action=>"single_vehicle_details", :id => vehicle.id}
    parent :transport_vehicle_report
  end
  crumb :transport_student_transport_details do |student|
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"student_transport_details", :id => student.id}
    parent :student_profile, student,student.user
  end
  crumb :transport_employee_transport_details do |employee|
    link I18n.t('transport.transport_details'), {:controller=>"transport", :action=>"employee_transport_details", :id => employee.id}
    parent :employee_profile, employee,employee.user
  end
  crumb :transport_fee_index do
    link I18n.t('transport_fee_text'), {:controller=>"transport_fee", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :transport_fee_transport_fee_collections do
    link I18n.t('transport_fee.fee_collection'), {:controller=>"transport_fee", :action=>"transport_fee_collections"}
    parent :transport_fee_index
  end
  crumb :transport_fee_transport_fee_collection_new do
    link "#{I18n.t('transport_fee.create_fee_collection_dates')} : #{I18n.t('batch')}-#{I18n.t('wise')}", {:controller=>"transport_fee", :action=>"transport_fee_collection_new"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_collection_creation_and_assign do
    link "#{I18n.t('transport_fee.user_wise_fee_collections')}", {:controller=>"transport_fee", :action=>"collection_creation_and_assign"}
    parent :transport_fee_transport_fee_collections
  end

  crumb :transport_fee_allocate_or_deallocate_fee_collection do
    link "#{I18n.t('manage')}  #{I18n.t('fee_collection')}", {:controller=>"transport_fee", :action=>"allocate_or_deallocate_fee_collection"}
    parent :transport_fee_transport_fee_collections
  end


  crumb :transport_fee_transport_fee_collection_create do
    link I18n.t('transport_fee.create_fee_collection_dates'), {:controller=>"transport_fee", :action=>"transport_fee_collection_new"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_transport_fee_collection_view do
    link I18n.t('transport_fee.view_transport_fee_collection_dates'), {:controller=>"transport_fee", :action=>"transport_fee_collection_view"}
    parent :transport_fee_transport_fee_collections
  end
  crumb :transport_fee_transport_fee_defaulters_view do
    link I18n.t('transport_fee.student_defaulters'), {:controller=>"transport_fee", :action=>"transport_fee_defaulters_view"}
    parent :transport_fee_pay_transport_fees
  end
  crumb :transport_fee_employee_defaulters_transport_fee_collection do
    link I18n.t('transport_fee.employee_defaulters'), {:controller=>"transport_fee", :action=>"employee_defaulters_transport_fee_collection"}
    parent :transport_fee_index
  end
  crumb :transport_fee_transport_fee_search do
    link I18n.t('transport.user_details'), {:controller=>"transport_fee", :action=>"transport_fee_search"}
    parent :transport_fee_pay_transport_fees
  end
  crumb :transport_fee_fees_student_dates do |student|
    link student.full_name, {:controller=>"transport_fee", :action=>"fees_student_dates", :id => student.id}
    parent :transport_fee_transport_fee_search
  end
  crumb :transport_fee_fees_employee_dates do |employee|
    link employee.full_name, {:controller=>"transport_fee", :action=>"fees_student_dates", :id => employee.id}
    parent :transport_fee_transport_fee_search
  end
  crumb :transport_fee_student_profile_fee_details do |fee|
    link I18n.t('transport_fee.transport_fee_status'), {:controller=>"transport_fee", :action=>"student_profile_fee_details", :id2 => fee.id, :id => fee.receiver_id}
    receiver = fee.receiver.present? ? fee.receiver : ArchivedStudent.find_by_former_id(fee.receiver_id)
    parent :student_fees, receiver
  end
  crumb :transport_fee_transport_fees_report do |date_range|
    additional_params = date_range.length > 2 ? {:fee_account_id => date_range[2]} : {}
    link I18n.t('transport_fees'), {:controller => "transport_fee", :action => "transport_fees_report",
      :start_date => date_range[0].to_date, :end_date => date_range[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, date_range
  end

  crumb :category_wise_transport_collection do |list|
    additional_params = list[1].length > 2 ? {:fee_account_id => list[1][2]} : {}
    link list.first.name, {:controller => "transport_fee", :action => "category_wise_collection_report",
      :id => list[0].id, :start_date => list[1][0].to_date, :end_date => list[1][1].to_date}.merge(additional_params)
    parent :transport_fee_transport_fees_report, list[1]
  end

  crumb :transport_fee_employee_transport_fees_report do |list|    
    additional_params = list[2].length > 2 ? {:fee_account_id => list[2][2]} : {}
    link "#{I18n.t('report')}-#{list.first.name}", {:controller => "transport_fee", 
      :action => "employee_transport_fees_report", :start_date => list[2][0].to_date,
      :end_date => list[2][1].to_date}.merge(additional_params)
    parent :category_wise_transport_collection, [list[1],list.last]
  end
  crumb :transport_fee_batch_transport_fees_report do |list|
    link list.first.full_name, {:controller=>"transport_fee", :action=>"batch_transport_fees_report",:start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :transport_fee_transport_fees_report,list.last
  end

  crumb :transport_fee_user_wise_transport_fees_report do |list|
    link "#{I18n.t('user_text')} #{I18n.t('wise')} #{I18n.t('fee_collection')}", {:controller=>"transport_fee", :action=>"batch_transport_fees_report",:start_date=>list.last.first.to_date,:end_date=>list.last.last.to_date}
    parent :transport_fee_transport_fees_report,list.last
  end

  crumb :transport_fee_pay_transport_fees do
    link I18n.t('pay_fees'), {:controller=>"transport_fee", :action=>"pay_transport_fees"}
    parent :transport_fee_index
  end

  crumb :transport_fee_pay_batch_wise do
    link "#{I18n.t('batch')}-#{I18n.t('wise')}", {:controller=>"transport_fee", :action=>"pay_batch_wise"}
    parent :transport_fee_pay_transport_fees
  end
  crumb :transport_reports do
    link "#{I18n.t('transport_text')} #{I18n.t('reports_text')}", {:controller=>"transport", :action=>"reports"}
    parent :transport_dash_board
  end
  crumb :transport_student_transport_report do
    link "#{I18n.t('course_text')} / #{I18n.t('batch')}-#{I18n.t('wise')} #{I18n.t('report').downcase}", {:controller=>"transport", :action=>"student_transport_report"}
    parent :transport_reports
  end
  crumb :transport_employee_transport_report do
    link "#{I18n.t('department')}-#{I18n.t('wise')} #{I18n.t('report').downcase}", {:controller=>"transport", :action=>"employee_transport_report"}
    parent :transport_reports
  end
  crumb :transport_route_report do
    link "#{I18n.t('routes.route')}-#{I18n.t('wise')} #{I18n.t('report').downcase}", {:controller=>"transport", :action=>"route_report"}
    parent :transport_reports
  end
  crumb :vehicles_assign_passengers do |vehicle|
    link I18n.t('assign_passengers'),  {:action=>"assign_passengers", :controller=>"vehicles", :id=>vehicle.id}
    parent :vehicles_show, vehicle
  end
  
  crumb :transport_configurations do
    link I18n.t('settings'),  {:controller => "transport", :action => "configurations"}
    parent :transport_dash_board
  end
  
  crumb :transport_settings do
    link I18n.t('basic_settings'),  {:controller => "transport", :action => "settings"}
    parent :transport_configurations
  end
  
  crumb :route_additional_details_index do
    link I18n.t('route_additional_details.route_additional_details_text'),  {:controller => "route_additional_details", :action => "index"}
    parent :transport_configurations
  end
  
  crumb :vehicle_additional_details_index do
     link I18n.t('vehicle_additional_details.vehicle_additional_details_text'),  {:controller => "vehicle_additional_details", :action => "index"}
    parent :transport_configurations
  end
   
  crumb :vehicle_certificate_types_index do
    link I18n.t('vehicle_certificate_types.vehicle_certificate_types'),  {:controller => "vehicle_certificate_types", :action => "index"}
    parent :transport_configurations
  end
  
  crumb :vehicle_stops_index do
    link I18n.t('vehicle_stops.stops'),  {:controller => "vehicle_stops", :action => "index"}
    parent :transport_dash_board
  end
  
  crumb :vehicle_certificates_index do |vehicle|
    link I18n.t('vehicle_certificates.vehicle_certificates_text'),  {:controller => "vehicle_certificates", :action => "index", :vehicle_id => vehicle.id}
     parent :vehicles_show, vehicle
  end
  
  crumb :vehicle_certificates_new do |vehicle|
    link I18n.t('vehicle_certificates.upload_certificates'),  {:controller => "vehicle_certificates", :action => "new", :vehicle_id => vehicle.id}
    parent :vehicle_certificates_index, vehicle
  end
  
  crumb :transport_employees_index do
    link I18n.t('transport_employees.manage_drivers_and_attendant'),  {:controller => "transport_employees", :action => "index"}
    parent :transport_dash_board
  end
  
  crumb :transport_employees_new do
    link I18n.t('transport_employees.assign_employees'),  {:controller => "transport_employees", :action => "new"}
    parent :transport_employees_index
  end
  
  crumb :transport_attendance_index do
    link I18n.t('transport_attendance.transport_attendance_text'),  {:controller => "transport_attendance", :action => "index"}
    parent :transport_dash_board
  end
  
  crumb :transport_imports_new do
    link I18n.t('transport_imports.transport_import_text'),  {:controller => "transport_imports", :action => "new"}
    parent :transport_dash_board
  end
  
  crumb :transport_imports_create do
    link I18n.t('transport_imports.transport_import_text'),  {:controller => "transport_imports", :action => "new"}
    parent :transport_dash_board
  end
  
  crumb :transport_imports_show do
    link I18n.t('transport_imports.transport_import_logs'),  {:controller => "transport_imports", :action => "show"}
    parent :transport_imports_new
  end
  
  crumb :transport_passenger_imports_index do |user|
    link I18n.t('transport_passenger_imports.import_passengers'), {:controller=>"transport", :action=>"download_structure"}
    parent :transport_index
  end
  
  crumb :transport_passenger_imports_create do |user|
    link I18n.t('transport_passenger_imports.import_passengers'), {:controller=>"transport", :action=>"download_structure"}
    parent :transport_index
  end
  
  crumb :transport_reports_index do
    link I18n.t('reports_text'), {:controller=>"transport_reports", :action=>"index"}
    parent :transport_dash_board
  end
  
  crumb :transport_send_notification do
    link I18n.t('notification'), {:controller=>"transport", :action=>"send_notification"}
    parent :transport_dash_board
  end
  
  crumb :transport_reports_report do |type|
    link I18n.t("transport_reports.#{type}"), {:controller=>"transport_reports", :action=>"report", :type => type}
    parent :transport_reports_index
  end
  
  crumb :routes_report_show do |details|
    link details.first.name, {:controller=>"routes", :action=>"show",:id=>details.first.id}
    parent :transport_reports_report, details.last
  end
  
  crumb :vehicle_maintenances_index do
    link I18n.t('vehicle_maintenances.vehicle_maintenance_text'), {:controller=>"vehicle_maintenances", :action=>"index"}
    parent :transport_dash_board
  end
  crumb :vehicle_maintenances_new do
    link I18n.t('vehicle_maintenances.add_maintenance_record'), {:controller=>"vehicle_maintenances", :action=>"new"}
    parent :vehicle_maintenances_index
  end
  crumb :vehicle_maintenances_show do |record|
    link record.name, {:controller=>"vehicle_maintenances", :action=>"show",:id=>record.id}
    parent :vehicle_maintenances_index
  end
  crumb :vehicle_maintenances_create do
    link I18n.t('vehicle_maintenances.add_maintenance_record'), {:controller=>"vehicle_maintenances", :action=>"new"}
    parent :vehicle_maintenances_index
  end
  crumb :vehicle_maintenances_edit do |record|
    link "#{I18n.t('edit_text')} - #{record.name_was}", {:controller=>"vehicle_maintenances", :action=>"edit", :id => record.id}
    parent :vehicle_maintenances_index
  end
  crumb  :transport_gps_settings_index do 
     link I18n.t('transport_gps_settings.gps_settings'), {:controller=>"transport_gps_setting", :action=>"index"}
    parent :transport_configurations
  end
  crumb  :transport_gps_syncs_index do 
     link I18n.t('transport_gps_syncs.sync'), {:controller=>"transport_gps_syncs", :action=>"index"}
    parent :transport_dash_board
  end
  
end
