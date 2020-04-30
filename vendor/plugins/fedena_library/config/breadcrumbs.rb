Gretel::Crumbs.layout do
  crumb :library_index do
    link I18n.t('library_text'), {:controller=>"library",:action=>"index"}
  end

  crumb :books_index do
    link I18n.t('manage_books'), {:controller=>"books",:action=>"index"}
    parent :library_index
  end

  crumb :library_search_book do
    link I18n.t('search_book_text'), {:controller=>"library",:action=>"search_book"}
    parent :library_index
  end

  crumb :book_movement_return_book do
    link I18n.t('return_book'), {:controller=>"book_movement",:action=>"return_book"}
    parent :library_index
  end

  crumb :book_movement_direct_issue_book do
    link I18n.t('issue_books'), {:controller=>"book_movement",:action=>"direct_issue_book"}
    parent :library_index
  end

  crumb :library_card_setting do
    link I18n.t('library_setting_text'), {:controller=>"library",:action=>"card_setting"}
    parent :library_index
  end

  crumb :library_movement_log do
    link I18n.t('movement_log_index'), {:controller=>"library",:action=>"movement_log"}
    parent :library_index
  end

  crumb :book_movement_renewal do
    link I18n.t('book_renewal'), {:controller=>"book_movement",:action=>"renewal"}
    parent :library_index
  end

  crumb :books_add_additional_details do
    link I18n.t('manage_book_additional_details'), {:controller=>"books",:action=>"add_additional_details"}
    parent :library_index
  end

  crumb :books_edit_additional_details do
    link I18n.t('manage_book_additional_details'), {:controller=>"books",:action=>"edit_additional_details"}
    parent :library_index
  end

  crumb :books_library_transactions do
    link I18n.t('books.library_fine_receipts'), {:controller=>"books",:action=>"library_transactions"}
    parent :library_index
  end

  crumb :books_new do
    link I18n.t('books.add_book'), {:controller=>"books",:action=>"new"}
    parent :books_index
  end

  crumb :books_create do
    link I18n.t('books.add_book'), {:controller=>"books",:action=>"create"}
    parent :books_index
  end

  crumb :books_show do |book|
    link book.title_was, {:controller=>"books",:action=>"show",:id=>book.id}
    parent :books_index
  end

  crumb :books_edit do |book|
    link I18n.t('books.edit_book'), {:controller=>"books",:action=>"edit",:id=>book.id}
    parent :books_show,book
  end

  crumb :books_manage_barcode do
    link I18n.t('books.manage_barcode'), {:controller=>"books",:action=>"manage_barcode"}
    parent :library_index
  end

  crumb :books_update_barcode do
    link I18n.t('books.manage_barcode'), {:controller=>"books",:action=>"manage_barcode"}
    parent :library_index
  end

  crumb :book_movement_issue_book do |book|
    link I18n.t('books.issue_book'), {:controller=>"book_movement",:action=>"issue_book",:id=>book.id}
    parent :books_show,book
  end

  crumb :books_additional_data do |book|
    link I18n.t('books.additional_data'), {:controller=>"books",:action=>"additional_data",:id=>book.id}
    parent :books_new
  end

  crumb :books_edit_additional_data do |book|
    link I18n.t('books.edit_additional_data'), {:controller=>"books",:action=>"edit_additional_data",:id=>book.id}
    parent :books_edit,book
  end

  crumb :library_employee_library_details do |employee|
    link I18n.t('library.library_details'), {:controller=>"library",:action=>"employee_library_details",:id=>employee.id}
    parent :employee_profile,employee,employee.user
  end

  crumb :library_student_library_details do |student|
    link I18n.t('library.library_details'), {:controller=>"library",:action=>"student_library_details",:id=>student.id}
    parent :student_profile,student,student.user
  end

  crumb :library_library_report do |list|
    additional_params = list.length > 2 ? {:fee_account_id => list[2]} : {}
    link I18n.t('library.library_transaction_report'), {:controller=>"library", :action => "library_report",
      :start_date => list[0].to_date, :end_date => list[1].to_date}.merge(additional_params)
    parent :finance_update_monthly_report, list
  end

  crumb :batch_library_report do |list|
    additional_params = list[1].length > 2 ? {:fee_account_id => list[1][2]} : {}    
    link list.first, {:controller=>"library",:action=>"batch_library_report", :start_date => list[1][0].to_date,
      :end_date => list[1][1].to_date}.merge(additional_params)
    parent :library_library_report, list.last
  end
  
  crumb :tags_index do
    link I18n.t('tags.manage_tags'), {:controller=>"tags",:action=>"index"}
    parent :library_index
  end
  crumb :tags_show do
    link I18n.t('tags.tagged_books'), {:controller=>"tags",:action=>"show"}
    parent :tags_index
  end
end