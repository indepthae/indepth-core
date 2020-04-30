Gretel::Crumbs.layout do

  crumb :groups_index do
    link I18n.t('groups.all_discussion'), {:controller=>"groups",:action=>"index"}
  end

  crumb :groups_new do
    link I18n.t('groups.create_new_group'), {:controller=>"groups",:action=>"new"}
    parent :groups_index
  end

  crumb :groups_create do
    link I18n.t('groups.create_new_group'), {:controller=>"groups",:action=>"create"}
    parent :groups_index
  end


  crumb :groups_show do |group|
    link group.group_name_was, {:controller=>"groups",:action=>"show",:id=>group.id}
    parent :groups_index
  end

  crumb :groups_edit do |group|
    link I18n.t('groups.edit_group'), {:controller=>"groups",:action=>"edit",:id=>group.id}
    parent :groups_show,group
  end

  crumb :groups_update do |group|
    link I18n.t('groups.edit_group'), {:controller=>"groups",:action=>"update",:id=>group.id}
    parent :groups_show,group
  end

  crumb :groups_members do |group|
    link I18n.t('groups.see_all_members'), {:controller=>"groups",:action=>"members",:id=>group.id}
    parent :groups_show,group
  end

  crumb :groups_recent_posts do
    link I18n.t('groups.recent_posts'), {:controller=>"groups",:action=>"recent_posts"}
    parent :groups_index
  end

   crumb :groups_group_posts do |post|
    link post.post_title, {:controller=>"groups",:action=>"group_posts",:id=>post.id}
    parent :groups_recent_posts
  end
end