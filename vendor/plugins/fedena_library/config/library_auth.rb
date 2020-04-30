#Copyright 2010 Foradian Technologies Private Limited
#This product includes software developed at
#Project Fedena - http://www.projectfedena.org/
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing,
#software distributed under the License is distributed on an
#"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
#KIND, either express or implied.  See the License for the
#specific language governing permissions and limitations
#under the License.
authorization do

  #custom - privileges
  role :students_control do
    has_permission_on [:library],
      :to => [:student_library_details]
  end
  role :student_view do
    has_permission_on [:library],
      :to => [:student_library_details]
  end

  #library module
  role :librarian do
    has_permission_on [:book_movement],
      :to => [
      :issue_book,
      :user_search,
      :update_user,
      :return_book,
      :return_book_detail,
      :update_return,
      :reserve_book,
      :direct_issue_book,
      :renewal,
      :update_renewal
    ]
    has_permission_on [:books],
      :to => [
      :index,
      :new,
      :create,
      :edit,
      :update,
      :show,
      :destroy,
      :sort_by,
      :add_additional_details,
      :change_field_priority,
      :edit_additional_details,
      :delete_additional_details,
      :additional_data,
      :edit_additional_data,
      :library_transactions,
      :search_library_transactions,
      :library_transaction_filter_by_date,
      :delete_library_transaction,
      :manage_barcode,
      :update_barcode,
      :list_barcode_field,
      :manage_books_csv_export,
      :generate_library_fine_receipt_pdf,
      :generate_library_fine_receipt,
      :get_library_fine_details,
      :search_books
      
    ]
    has_permission_on [:library],
      :to => [
      :index,
      :search_book,
      :search_result,
      :detail_search,
      :availabilty,
      :card_setting,
      :show_setting,
      :add_new_setting,
      :create_setting,
      :edit_card_setting,
      :update_card_setting,
      :delete_card_setting,
      :movement_log,
      :movement_log_csv,
      :library_report,
      :library_report_csv,
      :batch_library_report,
      :batch_library_report_csv,
      :student_library_details,
      :employee_library_details
    ]
    has_permission_on [:tags],:to => [ :index, :show, :set_tag_name, :search_tag_ajax, :destroy ]
  end
  #end library

  # admin privileges
  role :admin do

    includes :librarian
  end

  role :manage_users do
    has_permission_on [:library],
      :to=>[
      :student_library_details,
      :employee_library_details
    ]
  end
 role :employee_search do
    has_permission_on [:library],
      :to=>[
      :employee_library_details
    ]
 end
 role :hr_basics do
    has_permission_on [:library],
      :to=>[
      :employee_library_details
    ]
 end
  #employee - privileges
  role :employee do
    has_permission_on [:book_movement],
      :to => [
      :user_search,
      :update_user,
      :reserve_book
    ]
    has_permission_on [:books],
      :to => [
      :index,
      :show,
      :sort_by,
      :search_books
    ]
    has_permission_on [:library],
      :to => [
      :index,
      :search_book,
      :search_result,
      :detail_search,
      :availabilty
      ]
     has_permission_on [:library],
       :to =>[
          :employee_library_details
       ]do
      if_attribute :id => is {user.id}
    end
  end

  # student- privileges
  role :student do

    has_permission_on [:book_movement],
      :to => [

      :user_search,
      :update_user,
      :reserve_book
    ]
    has_permission_on [:books],
      :to => [
      :index,
      :show,
      :sort_by,
      :search_books

    ]
    has_permission_on [:library],
      :to => [
      :index,
      :search_book,
      :search_result,
      :detail_search,
      :availabilty ,
      :student_library_details]
    #end library------

  end
  role :finance_reports do
    has_permission_on [:library],
      :to => [:library_report,
      :batch_library_report,
      :library_report_pdf,
      :show_date_filter,
      :batch_library_report_csv,
      :library_report_csv,
      :batch_library_report_pdf
    ]
  end
end
