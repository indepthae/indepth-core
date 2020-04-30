Gretel::Crumbs.layout do

  crumb :hostels_hostel_dashboard do
    link I18n.t('hostels.hostel_text'), {:controller=>"hostels",:action=>"hostel_dashboard"}
  end

  crumb :hostels_index do
    link I18n.t('hostels.all_hostels'), {:controller=>"hostels",:action=>"index"}
    parent :hostels_hostel_dashboard
  end

  crumb :room_details_index do
    link I18n.t('room_details.room_details'), {:controller=>"room_details",:action=>"index"}
    parent :hostels_hostel_dashboard
  end

  crumb :room_allocate_index do
    link I18n.t('room_allocate.room_allocation_text'), {:controller=>"room_allocate",:action=>"index"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostel_fee_hostel_fee_collection do
    link I18n.t('hostel_fee.fee_collection'), {:controller=>"hostel_fee",:action=>"hostel_fee_collection"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostel_fee_hostel_fee_pay do
    link I18n.t('hostel_fee.pay_hostel_fee'), {:controller=>"hostel_fee",:action=>"hostel_fee_pay"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostel_fee_hostel_fee_defaulters do
    link I18n.t('hostel_fee.view_hostel_fee_defaulters'), {:controller=>"hostel_fee",:action=>"hostel_fee_defaulters"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostel_fee_index do
    link I18n.t('hostel_fee.search_student'), {:controller=>"hostel_fee",:action=>"index"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostels_room_availability_details do
    link I18n.t('hostels.room_availability_details'), {:controller=>"hostels",:action=>"room_availability_details"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostels_new do
    link I18n.t('hostels.add_hostel'), {:controller=>"hostels",:action=>"new"}
    parent :hostels_index
  end

  crumb :hostels_create do
    link I18n.t('hostels.add_hostel'), {:controller=>"hostels",:action=>"create"}
    parent :hostels_index
  end

  crumb :hostels_show do |hostel|
    link hostel.name_was, {:controller=>"hostels",:action=>"show",:id=>hostel.id}
    parent :hostels_index
  end

  crumb :hostels_edit do |hostel|
    link I18n.t('hostels.edit_hostel'), {:controller=>"hostels",:action=>"edit",:id=>hostel.id}
    parent :hostels_show,hostel
  end

  crumb :hostels_update do |hostel|
    link I18n.t('hostels.edit_hostel'), {:controller=>"hostels",:action=>"update",:id=>hostel.id}
    parent :hostels_show,hostel
  end

  crumb :hostels_add_additional_details do
    link I18n.t('hostels.add_hostel_additional_details'), {:controller=>"hostels",:action=>"add_additional_details"}
    parent :hostels_hostel_dashboard
  end

  crumb :hostels_edit_additional_details do
    link I18n.t('hostels.edit_hostel_additional_details'), {:controller=>"hostel",:action=>"edit_additional_details"}
    parent :hostels_hostel_dashboard
  end

 
  crumb :room_details_add_additional_details do
    link I18n.t('room_details.add_room_additional_details'), {:controller=>"room_details",:action=>"add_additional_details"}
    parent :hostels_hostel_dashboard
  end

  crumb :room_details_edit_additional_details do
    link I18n.t('room_details.edit_room_additional_details'), {:controller=>"room_details",:action=>"edit_additional_details"}
    parent :hostels_hostel_dashboard
  end

  crumb :room_details_show do |room|
    link room.room_number_was, {:controller=>"room_details",:action=>"show",:id=>room.id}
    parent :room_details_index
  end

  crumb :room_details_edit do |room|
    link I18n.t('room_details.edit_room'), {:controller=>"room_details",:action=>"edit",:id=>room.id}
    parent :room_details_show,room
  end

  crumb :room_details_update do |room|
    link I18n.t('room_details.edit_room'), {:controller=>"room_details",:action=>"update",:id=>room.id}
    parent :room_details_show,room
  end

  crumb :room_details_new do
    link I18n.t('room_details.add_new_room'), {:controller=>"room_details",:action=>"new"}
    parent :room_details_index
  end

  crumb :room_details_create do
    link I18n.t('room_details.add_new_room'), {:controller=>"room_details",:action=>"create"}
    parent :room_details_index
  end

  crumb :room_allocate_assign_room do
    link I18n.t('room_allocate.allocate'), {:controller=>"room_details",:action=>"new"}
    parent :room_allocate_index
  end
  
  crumb :room_allocate_change_room do |room|
    link I18n.t('room_allocate.change_allocation'), {:controller=>"room_allocate",:action=>"change_room",:id=>room.id}
    parent :room_details_show,room.room_detail
  end

  crumb :hostel_fee_hostel_fee_collection_new do
    link "#{I18n.t('hostel_fee.create_hostel_fee_collection_date')} : #{I18n.t('batch')}-#{I18n.t('wise')}", {:controller=>"hostel_fee",:action=>"hostel_fee_collection_new"}
    parent :hostel_fee_hostel_fee_collection
  end

  crumb :hostel_fee_collection_creation_and_assign do
    link "#{I18n.t('hostel_fee.user_wise_fee_collections')}", {:controller=>"hostel_fee",:action=>"collection_creation_and_assign"}
    parent :hostel_fee_hostel_fee_collection
  end

  crumb :hostel_fee_allocate_or_deallocate_fee_collection do
    link "#{I18n.t('manage')}  #{I18n.t('fee_collection')}", {:controller=>"hostel_fee",:action=>"allocate_or_deallocate_fee_collection"}
    parent :hostel_fee_hostel_fee_collection
  end

  crumb :hostel_fee_hostel_fee_collection_create do
    link I18n.t('hostel_fee.create_hostel_fee_collection_date'), {:controller=>"hostel_fee",:action=>"hostel_fee_collection_create"}
    parent :hostel_fee_hostel_fee_collection
  end

  crumb :hostel_fee_hostel_fee_collection_view do
    link I18n.t('hostel_fee.hostel_fee_collection_view'), {:controller=>"hostel_fee",:action=>"hostel_fee_collection_view"}
    parent :hostel_fee_hostel_fee_collection
  end

  crumb :hostel_fee_student_hostel_fee do |student|
    link I18n.t('hostel_fee.student_hostel_fee'), {:controller=>"hostel_fee",:action=>"student_hostel_fee",:id=>student.id}
    parent :hostel_fee_index
  end

  crumb :hostels_room_list do |room|
    link I18n.t('hostels.rooms'), {:controller=>"hostels",:action=>"room_list",:id=>room.id}
    parent :hostels_room_availability_details
  end

  crumb :hostels_individual_room_details do |room|
    link room.first.room_number, {:controller=>"hostels",:action=>"individual_room_details",:id=>room.first.id}
    parent :hostels_room_list,Hostel.find(room.last)
  end

  crumb :hostels_student_hostel_details do |student|
    link I18n.t('hostels.hostel_details'), {:controller=>"hostels",:action=>"student_hostel_details",:id=>student.id}
    parent :student_profile,student,student.user
  end

  crumb :wardens_index do |hostel|
    link I18n.t('wardens.all_wardens'), {:controller=>"wardens",:action=>"index",:hostel_id=>hostel.id}
    parent :hostels_show,hostel
  end

  crumb :wardens_new do |hostel|
    link I18n.t('wardens.add_warden'), {:controller=>"wardens",:action=>"new",:hostel_id=>hostel.id}
    parent :wardens_index,hostel
  end

  crumb :wardens_create do |hostel|
    link I18n.t('wardens.add_warden'), {:controller=>"wardens",:action=>"create",:hostel_id=>hostel.id}
    parent :wardens_index,hostel
  end

  crumb :hostel_fee_hostel_fees_report do |list|
    additional_params = list.length > 2 ? {:fee_account_id => list[2]} : {}
    link I18n.t('hostel_fees'), {:controller => "hostel_fee", :action => "hostel_fees_report",
      :start_date => list[0].to_date, :end_date => list[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, list
  end

  crumb :course_wise_hostel_fee_collection do |list|
    additional_params = list[1].length > 2 ? {:fee_account_id => list[1][2]} : {}
    link list.first.name, {:controller => "hostel_fee", :action => "hostel_fees_report", :id => list[0].id,
      :start_date => list[1][0].to_date, :end_date => list[1][1].to_date}.merge(additional_params)
    parent :hostel_fee_hostel_fees_report, list[1]
  end
  
  crumb :hostel_fee_batch_hostel_fees_report do |list|
    additional_params = list[2].length > 2 ? {:fee_account_id => list[2][2]} : {}
    link list[0].full_name, {:controller => "hostel_fee", :action => "batch_hostel_fees_report", 
      :id => list[0].id}.merge(additional_params)
    parent :course_wise_hostel_fee_collection, [list[1],list.last]
  end

  crumb :hostel_fee_student_wise_hostel_fees_report do |list|
    link "#{I18n.t('student_text')} #{I18n.t('wise')} #{I18n.t('fee_collection')}", {:controller=>"hostel_fee",:action=>"batch_hostel_fees_report",:id=>list.first.id}
    parent :hostel_fee_hostel_fees_report,list.last
  end

  crumb :hostel_fee_student_profile_fee_details do |fee|
    link I18n.t('hostel_fee.hostel_fee_status'), {:controller=>"hostel_fee", :action=>"student_profile_fee_details", :id2 => fee.last.id, :id => fee.first.id}
    parent :student_fees, fee.first
  end
end