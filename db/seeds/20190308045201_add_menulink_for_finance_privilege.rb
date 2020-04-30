administration_cat = MenuLinkCategory.find_by_name("administration")
unless administration_cat.nil?
  a = administration_cat.allowed_roles
  a.push([ :fees_submission_without_discount])
  a.flatten!
  administration_cat.allowed_roles = a.uniq
  administration_cat.save

end