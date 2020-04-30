Gretel::Crumbs.layout do

  crumb :galleries_index do
    link I18n.t('galleries.gallery'), {:controller=>"galleries",:action=>"index"}
  end
  crumb :galleries_archived_albums do
    link I18n.t('galleries.old_albums'), {:controller=>"galleries",:action=>"archived_albums"}
    parent :galleries_index
  end

  crumb :galleries_old_category_show do |category|
    link category.name_was, {:controller=>"galleries",:action=>"old_category_show",:id=>category.id}
    current_user  = Authorization.current_user
    parent :galleries_archived_albums, (current_user.parent? ? (current_user.guardian_entry.current_ward.user) : (current_user))
  end

   crumb :galleries_photo_add do
    link I18n.t('galleries.add_images'), {:controller=>"galleries",:action=>"photo_add"}
    parent :galleries_index
  end

  crumb :galleries_unpublished_albums do
   link I18n.t('galleries.unpublished_albums'), {:controller=>"galleries",:action=>"photo_add"}
   parent :galleries_index
 end

   crumb :galleries_photo_create do
    link I18n.t('galleries.add_images'), {:controller=>"galleries",:action=>"photo_create"}
    parent :galleries_index
  end

  crumb :galleries_category_new do
    link I18n.t('galleries.add_category'), {:controller=>"galleries",:action=>"category_new"}
    parent :galleries_index
  end

  crumb :galleries_category_create do
    link I18n.t('galleries.add_category'), {:controller=>"galleries",:action=>"category_create"}
    parent :galleries_index
  end

  crumb :galleries_category_show do |category|
    link category.name_was, {:controller=>"galleries",:action=>"category_show",:id=>category.id}
    current_user  = Authorization.current_user
    parent :galleries_index, (current_user.parent? ? (current_user.guardian_entry.current_ward.user) : (current_user))
  end

  crumb :galleries_category_more_option do |category|
    link I18n.t('galleries.delete_photos'), {:controller=>"galleries",:action=>"more_option",:id=>category.id}
    parent :galleries_category_show, category
  end

  crumb :galleries_category_old_more_option do |category|
    link I18n.t('galleries.delete_photos'), {:controller=>"galleries",:action=>"more_option",:id=>category.id}
    parent :galleries_old_category_show, category
  end

  crumb :galleries_search_album do
    link I18n.t('galleries.search'), {:controller=>"galleries",:action=>"search_album"}
    parent :galleries_index
  end

  crumb :galleries_category_edit do |category|
    link I18n.t('galleries.edit_album'), {:controller=>"galleries",:action=>"category_edit",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_category_update do |category|
    link I18n.t('galleries.edit_category'), {:controller=>"galleries",:action=>"category_update",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_add_photo do |category|
    link I18n.t('galleries.add_images'), {:controller=>"galleries",:action=>"add_photo",:id=>category.id}
    parent :galleries_category_show,category
  end

  crumb :galleries_edit_photo do |list|
    link I18n.t('galleries.edit_photo'), {:controller=>"galleries",:action=>"edit_photo",:id=>list.first.id}
    parent :galleries_category_show,list.last
  end
end
