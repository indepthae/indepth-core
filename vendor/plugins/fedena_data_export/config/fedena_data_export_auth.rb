authorization do

  role :custom_export do
    has_permission_on [:data_exports],:to=>[
      :index,
      :new,
      :create,
      :download_export_file
    ]

    has_permission_on [:scheduled_jobs],:to => [:index]
  end

  role :masteradmin do
    includes  :custom_export
  end

  role :admin do
    includes  :custom_export
  end

end