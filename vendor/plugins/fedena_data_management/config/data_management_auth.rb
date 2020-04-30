authorization do

  role :data_management_viewer do
    has_permission_on [:school_assets],
      :to => [
      :index,
      :show]
    has_permission_on [:asset_entries],
      :to => [
      :index,
      :show,
      :assets_pdf,
      :school_assets_pdf,
      :find_school_asset]
  end

  role :data_management  do
    has_permission_on [:school_assets],
      :to => [
      :index,
      :new,
      :show,
      :edit,
      :create,
      :update,
      :destroy]
    has_permission_on [:asset_entries],
      :to => [
      :index,
      :show,
      :assets_pdf,
      :school_assets_pdf,
      :new,
      :create,
      :edit,
      :update,
      :destroy,
      :find_school_asset]
  end

  
  role :admin do
    includes :data_management
  end

end