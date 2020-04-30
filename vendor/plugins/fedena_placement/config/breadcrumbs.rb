Gretel::Crumbs.layout do

  crumb :placementevents_index do
    link I18n.t('placementevents.placements'), {:controller=>"placementevents",:action=>"index"}
  end

  crumb :placementevents_new do
    link I18n.t('placementevents.announce_new_placements'), {:controller=>"placementevents",:action=>"new"}
    parent :placementevents_index
  end

  crumb :placementevents_create do
    link I18n.t('placementevents.announce_new_placements'), {:controller=>"placementevents",:action=>"create"}
    parent :placementevents_index
  end

  crumb :placementevents_archive do
    link I18n.t('placementevents.archived_placements'), {:controller=>"placementevents",:action=>"archive"}
    parent :placementevents_index
  end



  crumb :placementevents_archive_show do |placement|
    link placement.title_was, {:controller=>"placementevents",:action=>"show",:id=>placement.id}
    parent :placementevents_archive
  end




  crumb :placementevents_show do |placement|
    link placement.title_was, {:controller=>"placementevents",:action=>"show",:id=>placement.id}
    parent :placementevents_index
  end

  crumb :placementevents_edit do |placement|
    link I18n.t('placementevents.edit_placement_event'), {:controller=>"placementevents",:action=>"edit",:id=>placement.id}
    parent :placementevents_show,placement
  end

  crumb :placementevents_update do |placement|
    link I18n.t('placementevents.edit_placement_event'), {:controller=>"placementevents",:action=>"update",:id=>placement.id}
    parent :placementevents_show,placement
  end

  crumb :placementevents_invite do |placement|
    link I18n.t('placementevents.invite_students'), {:controller=>"placementevents",:action=>"invite",:id=>placement.id}
    parent :placementevents_show,placement
  end

  crumb :placement_registrations_show do |placement_registration|
    link I18n.t('placementevents.view_invitation'), {:controller=>"placement_registrations",:action=>"show",:id=>placement_registration.id}
    parent :placementevents_show,placement_registration.placementevent
  end

  crumb :placement_registrations_index do |placementevent|
    link I18n.t('placementevents.registrations'), {:controller=>"placement_registrations",:action=>"index",:id=>placementevent.id}
    parent :placementevents_show,placementevent
  end

  crumb :placementevents_report do |placement|
    link I18n.t('placementevents.placement_report'), {:controller=>"placementevents",:action=>"report",:id=>placement.id}
    parent :placementevents_show,placement
  end
end