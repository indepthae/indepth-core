authorization do

  role :general_settings do
    includes :app_frame_admin
  end

  role :app_frame_admin do
    has_permission_on [:app_frames],
      :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :app_frame,
      :show
    ]
  end

  role :masteradmin do
  end

  role :admin do
    includes :app_frame_admin
  end

  role :student do
    has_permission_on [:app_frames],
      :to => [
      :app_frame
    ]
  end

  role :employee do
    has_permission_on [:app_frames],
      :to => [
      :app_frame
    ]
  end

  role :parent do
    has_permission_on [:app_frames],
      :to => [
      :app_frame
    ]
  end

end