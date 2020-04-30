Gretel::Crumbs.layout do
  crumb :discipline_complaints_index do
    link I18n.t('discipline'), {:controller=>"discipline_complaints", :action=>"index"}
  end
  crumb :discipline_complaints_new do
    link I18n.t('new_text'), {:controller=>"discipline_complaints", :action=>"new"}
    parent :discipline_complaints_index
  end
  crumb :discipline_complaints_create do
    link I18n.t('new_text'), {:controller=>"discipline_complaints", :action=>"new"}
    parent :discipline_complaints_index
  end
  crumb :discipline_complaints_show do |discipline_complaint|
    link discipline_complaint.complaint_no_was, {:controller=>"discipline_complaints", :action=>"show", :id => discipline_complaint.id }
    parent :discipline_complaints_index
  end
  crumb :discipline_complaints_edit do |discipline_complaint|
    link I18n.t('edit_text'), {:controller=>"discipline_complaints", :action=>"edit", :id => discipline_complaint.id }
    parent :discipline_complaints_show, discipline_complaint
  end
  crumb :discipline_complaints_update do |discipline_complaint|
    link I18n.t('edit_text'), {:controller=>"discipline_complaints", :action=>"edit", :id => discipline_complaint.id }
    parent :discipline_complaints_show, discipline_complaint
  end
  crumb :discipline_complaints_decision do |discipline_complaint|
    link I18n.t('discipline_complaints.decision'), {:controller=>"discipline_complaints", :action=>"decision", :id => discipline_complaint.id }
    parent :discipline_complaints_show, discipline_complaint
  end
end
