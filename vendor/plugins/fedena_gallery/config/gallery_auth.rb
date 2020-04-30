authorization do

  role :student_view do
#    includes :gallery_student
  end

  role :gallery_student do
    has_permission_on [:galleries],
      :to=>[
      :category_show,:show_image,:download_image,:index, :archived_albums,:old_category_show]
  end

  role :students_control do
#    includes :gallery_student
  end

  role :manage_users do
#    includes :gallery_student
  end

  role :photo_admin do
    has_permission_on [:galleries],
      :to=>[:index,:category_new,:category_create,:category_show,:category_delete,:category_edit,:category_update,:add_photo,:create_photo,:show_image,:download_image,:update_recipient_list1,:update_recipient_list,:select_student_course,:to_students,:to_employees,:select_users,:select_employee_department,:edit_photo,:photo_delete,:photo_add,:photo_create,:gallery_carousel,:more_option,:delete_multiple_photos,:batch_students,:set_publish,:unpublished_albums,:edit_photo_description,:search_album,
        :department_employees,:archived_albums,:old_category_show,:old_photo_delete]
  end

  role :admin do
    includes :photo_admin
  end

  role :gallery do
    has_permission_on [:galleries],
      :to=>[:index,:category_new,:category_create,:category_show,:category_delete,:category_edit,:category_update,:add_photo,:create_photo,:show_image,:download_image,:update_recipient_list1,:update_recipient_list,:select_student_course,:to_students,:to_employees,:select_users,:select_employee_department,:edit_photo,:photo_delete,:photo_add,:photo_create,:gallery_carousel,:more_option,:delete_multiple_photos,:batch_students,:set_publish,:unpublished_albums,:edit_photo_description,:search_album,
        :department_employees,:archived_albums,:old_category_show,:old_photo_delete]
  end

  role :employee do
    has_permission_on [:galleries],
      :to=>[
      :category_show,:show_image,:download_image,:index, :archived_albums,:old_category_show]
  end

  role :student do
    includes :gallery_student
  end

  role :parent do
   has_permission_on [:galleries],
      :to=>[
      :category_show,:show_image,:download_image,:index, :archived_albums,:old_category_show
   ],:join_by=> :and do
      if_attribute :assess_truth  => is {user.gallery_access?}
      if_attribute :id => is {user.parent_record.user_id}
    end
  end


end
