ActionController::Routing::Routes.draw do |map|

  map.resources :data_palettes, :collection=>{:update_palette=>[:post], :toggle_minimize=>[:post], :remove_palette=>[:post], :refresh_palette=>[:post], :show_palette_list=>[:post], :modify_user_palettes=>[:get,:post], :sort_palettes=>[:post], :view_more=>[:post]}
  
end
