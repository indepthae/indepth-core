cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  a = cat.allowed_roles
  a.delete(:add_new_batch)
  a.push(:manage_course_batch)
  a.flatten!
  cat.allowed_roles = a.uniq
  cat.save

end