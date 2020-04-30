cat = MenuLinkCategory.find_by_name("administration")
unless cat.nil?
  unless cat.allowed_roles.include?(:inventory_sales)
    cat.allowed_roles.push(:inventory_sales)
    cat.save
  end
end
