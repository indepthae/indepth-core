authorization do

role :poll_control_basic do
  has_permission_on [:poll_questions],
      :to => [
      :index,
      ]
  has_permission_on [:poll_questions],
   :to => [
     :voting
     ] do
    if_attribute :poll_members => {:users_list => contains {user}}
  end
  has_permission_on [:poll_questions],
      :to => [:show ] ,:join_by => :or  do
        if_attribute :poll_creator_id => is { user.id }
        if_attribute :voted_users_list => contains { user }
        # if_attribute :is_voted? => is { true }
      end
end


  role :poll_control  do
    has_permission_on [:poll_questions],
      :to => [
      :index,
      :new,
      :show,
      :edit,
      :create,
      :update,
      :destroy,
      :voting,
      :close_poll,
      :open_poll]
  end

  # admin privileges
  role :admin do
  includes :poll_control
  end

  # employee -privileges
  role :employee do
  includes :poll_control_basic
  end

  role :student do
  includes :poll_control_basic
  end
end
