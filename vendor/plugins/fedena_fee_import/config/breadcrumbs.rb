Gretel::Crumbs.layout do
  crumb :fee_imports_select_student do
    link I18n.t('fee_imports'), {:controller=>"fee_imports", :action=>"select_student"}
    parent :finance_fees_index
  end
  crumb :fee_imports_import_fees do|student|
    link I18n.t('import_fees'), {:controller=>"fee_imports",:action=>"import_fees",:id=>student.id}
    parent :student_profile,student
  end
end
