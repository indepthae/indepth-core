MenuLinkCategory.all.each do |category|
	roles = category.allowed_roles
	roles << :general_admin
	category.update_attribute(:allowed_roles, roles)
end