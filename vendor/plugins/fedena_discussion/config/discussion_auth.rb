authorization do
  role :admin do
    includes :group_basics
    includes :group_create
  end

  role :student do
    includes :group_basics
  end

  role :employee do
    includes :group_basics
  end

  role :group_basics do
    has_permission_on [:groups],
      :to => [
      :index,
      :show,
      :recent_posts,
      :members,
      :select_users,
      :select_student_course,
      :to_employees,
      :to_students,
      :to_schools,
      :update_recipient_list,
      :switch_between_admin_and_normal,
      :update_recipient_list1
    ]
    has_permission_on [:groups],
      :to => [
        :edit,
        :update,
        :destroy
      ]
    has_permission_on [:group_posts],
      :to => [
      :member_destroy,
      :show,
      :list_post_comments
    ]
    has_permission_on [:group_posts],
      :to => [
      :create
    ]do
      if_attribute :members => contains {user}
    end
    has_permission_on [:group_posts],
      :to=> [
        :update,
        :destroy
    ],:join_by => :or  do
      if_attribute :user_id => is  {user.id}
      if_attribute :group => {:user_id=> is {user.id}}
    end
    has_permission_on [:group_post_comments],
      :to => [
      :create
    ]
    has_permission_on [:group_post_comments],
      :to => [
      :destroy
    ],:join_by => :or  do
      if_attribute :user_id => is  {user.id}
      if_attribute :group_post => {:user_id=> is {user.id}}
    end
  end

  role :group_create do
    has_permission_on [:groups],
      :to => [
      :index,
      :show,
      :recent_posts,
      :members,
      :select_users,
      :select_student_course,
      :to_employees,
      :to_students,
      :to_schools,
      :update_recipient_list,
      :new,
      :edit,
      :create,
      :update,
      :destroy,
      :admin_destroy,
      :switch_between_admin_and_normal,
      :who_can_update_group,
      :update_recipient_list1
    ]
    has_permission_on [:group_posts],
      :to => [
      :create,
      :update,
      :destroy,
      :member_destroy,
      :show,
      :list_post_comments]
    has_permission_on [:group_post_comments],
      :to => [
      :create,
      :destroy]
  end
end
