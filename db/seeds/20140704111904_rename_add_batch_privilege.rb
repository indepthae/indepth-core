p=Privilege.find_by_name('AddNewBatch')
if p.present?
  p.update_attributes(:name=>'ManageCourseBatch',:description=>'manage_course_batch_privilege')
end