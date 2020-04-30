module UserGroupsHelper
  def is_permitted_to_delete
    if permitted_to? :destroy_user_group, :user_groups
      true
    else
      false
    end
  end
end
