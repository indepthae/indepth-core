cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  unless cat.allowed_roles.include?(:manage_users)
    cat.allowed_roles.push(:manage_users)
    cat.save
  end
end