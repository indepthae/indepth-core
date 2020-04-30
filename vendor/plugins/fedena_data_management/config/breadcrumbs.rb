Gretel::Crumbs.layout do

  crumb :school_assets_index do
    link I18n.t('school_assets.categories'), {:controller=>"school_assets",:action=>"index"}
  end

  crumb :school_assets_new do
    link I18n.t('school_assets.add_field'), {:controller=>"school_assets",:action=>"new"}
    parent :school_assets_index
  end

  crumb :school_assets_create do
    link I18n.t('school_assets.add_field'), {:controller=>"school_assets",:action=>"create"}
    parent :school_assets_index
  end

  crumb :school_assets_edit do |school_asset|
    link I18n.t('school_assets.edit'), {:controller=>"school_assets",:action=>"edit", :id => school_asset.id}
    parent :asset_entries_index, school_asset
  end

  crumb :school_assets_update do |school_asset|
    link I18n.t('school_assets.edit'), {:controller=>"school_assets",:action=>"edit", :id => school_asset.id}
    parent :asset_entries_index, school_asset
  end

crumb :asset_entries_index do |asset|
    link asset.asset_name_was, {:controller=>"asset_entries",:action=>"index",:school_asset_id => asset.id}
    parent :school_assets_index
  end

crumb :asset_entries_new do |list|
    link I18n.t('asset_entries.manage_entry'), {:controller=>"asset_entries",:action=>"new"}
    parent :asset_entries_index,list.first
  end

  crumb :asset_entries_create do |asset|
    link I18n.t('asset_entries.new_entry'), {:controller=>"asset_entries",:action=>"create"}
    parent :asset_entries_index,asset
  end


  crumb :asset_entries_edit do |list|
    link I18n.t('school_assets.edit'), {:controller=>"asset_entries",:action=>"edit",:id=>list.last.id}
    parent :asset_entries_show,list
  end

   crumb :asset_entries_update do |list|
    link I18n.t('school_assets.edit'), {:controller=>"asset_entries",:action=>"update",:id=>list.last.id}
    parent :asset_entries_show,list
  end

  crumb :asset_entries_show do |list|
    link list.first.asset_entry_name(list.last.id), {:controller=>"asset_entries",:action=>"show",:id=>list.last.id}
    parent :asset_entries_index,list.first
  end
  
end