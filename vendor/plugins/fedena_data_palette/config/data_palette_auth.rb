authorization do

  role :data_palette do
    has_permission_on [:data_palettes],
      :to=>[
      :index,
      :update_palette,
      :toggle_minimize,
      :remove_palette,
      :refresh_palette,
      :show_palette_list,
      :modify_user_palettes,
      :sort_palettes,
      :view_more
      ]
  end


  role :admin do
    includes :data_palette
  end

  role :employee do
    includes :data_palette
  end

  role :student do
    includes :data_palette
  end

  role :parent do
    includes :data_palette
  end



end