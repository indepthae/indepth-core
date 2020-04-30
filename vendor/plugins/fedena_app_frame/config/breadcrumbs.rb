Gretel::Crumbs.layout do
  crumb :app_frames_index do
    link I18n.t('app_frames.app_frames_text'), {:controller=>"app_frames", :action=>"index"}
  end
  crumb :app_frames_new do
    link I18n.t('new_text'), {:controller=>"app_frames", :action=>"new"}
    parent :app_frames_index
  end
  crumb :app_frames_create do
    link I18n.t('new_text'), {:controller=>"app_frames", :action=>"new"}
    parent :app_frames_index
  end
  crumb :app_frames_show do |app_frame|
    link app_frame.name_was, {:controller=>"app_frames", :action=>"show", :id => app_frame.id }
    parent :app_frames_index
  end
  crumb :app_frames_edit do |app_frame|
    link I18n.t('edit_text'), {:controller=>"app_frames", :action=>"edit", :id => app_frame.id }
    parent :app_frames_show, app_frame
  end
  crumb :app_frames_update do |app_frame|
    link I18n.t('edit_text'), {:controller=>"app_frames", :action=>"edit", :id => app_frame.id }
    parent :app_frames_show, app_frame
  end
  crumb :app_frames_app_frame do |app_frame|
    link "#{app_frame.name} - #{I18n.t('app_frames.app_frame_text')}", {:controller=>"app_frames", :action=>"app_frame", :id => app_frame.id }
    parent :app_frames_index
  end
end
