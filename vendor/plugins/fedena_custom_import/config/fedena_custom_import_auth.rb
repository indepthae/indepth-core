authorization do
  role :custom_import do
    has_permission_on [:exports], :to => [
      :index,
      :new,
      :edit,
      :create_import_for_edit,
      :create,
      :populate_associates,
      :show_associated_columns,
      :export_csv,
      :destroy
    ]
    has_permission_on [:imports], :to => [
      :index,
      :new,
      :edit,
      :create_import_for_edit,
      :create,
      :show,
      :destroy,
      :filter
    ]
    has_permission_on [:import_log_details], :to => [
      :index,
      :filter
    ]
    has_permission_on [:scheduled_jobs], :to => [:index]
  end

  role :masteradmin do
    includes  :custom_import
  end

  role :admin do
    includes  :custom_import
  end
end