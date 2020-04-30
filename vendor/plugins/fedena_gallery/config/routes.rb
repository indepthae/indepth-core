ActionController::Routing::Routes.draw do |map|

  #gallery
  map.resources :galleries, :collection=>[:category_new,:category_create,:category_show,:category_delete,:category_edit,:category_update,:add_photo,:create_photo,:show_image,:download_image,:update_recipient_list1,:update_recipient_list,:select_student_course,:to_students,:to_employees,:select_users,:select_employee_department,:edit_photo,:photo_delete,:update_photo,:photo_add,:photo_create,:more_option,:delete_multiple_photos,:batch_students,:set_publish,:unpublished_albums,:edit_photo_description, :search_album,
    :department_employees,:archived_albums,:old_category_show,:old_photo_delete]
end
