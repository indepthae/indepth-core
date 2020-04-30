ActionController::Routing::Routes.draw do |map|
  map.resources :school_assets do |school_asset|
    school_asset.resources :asset_entries
  end
end