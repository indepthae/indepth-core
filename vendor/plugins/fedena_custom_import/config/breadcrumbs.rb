Gretel::Crumbs.layout do
  crumb :exports_index do
   link I18n.t('exports.all_exports'), {:controller => "exports", :action => "index"}
 end

  crumb :exports_new do
    link I18n.t('exports.new_export'), {:controller => "exports", :action => "new"}
    parent :exports_index
  end

  crumb :exports_create do
    link I18n.t('exports.new_export'), {:controller => "exports", :action => "create"}
    parent :exports_index
  end

  crumb :imports_index do |export|
    link I18n.t('imports.all_imports'), {:controller => "imports", :action => "index", :export_id => export.id}
    parent :exports_index
  end

  crumb :imports_new do
    link I18n.t('imports.new_import'), {:controller => "imports", :action => "new"}
    parent :exports_index
  end

  crumb :imports_edit do
    link I18n.t('edit'), {:controller => "imports", :action => "edit"}
    parent :exports_index
  end

  crumb :imports_create_import_for_edit do
    link I18n.t('edit'), {:controller => "imports", :action => "create_import_for_edit"}
    parent :exports_index
  end

  crumb :imports_create do
    link I18n.t('imports.new_import'), {:controller => "imports", :action => "create"}
    parent :exports_index
  end

  crumb :import_log_details_index do |list|
    link I18n.t('import_log_details.detail_log'), {:controller => "import_log_details", :action => "index", :import_id => list.first.id}
    parent :imports_index, list.last
  end

  crumb :exports_schedule_jobs do
    link I18n.t('import_log_details.scheduled_jobs'), {:controller => "scheduled_jobs", :action => "index"}
    parent :exports_index
   
  end
end