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
FinanceTransactionCategory.find_or_create_by_name(:name=>"Library",:is_income=>true,:description=>"Library Module for Fedena")
Privilege.find_or_create_by_name :name => "Librarian",:description=>"librarian_privilege"
Tag.find_or_create_by_name(:name=>"Reference Book")
Privilege.reset_column_information
if Privilege.column_names.include?("privilege_tag_id")
  Privilege.find_by_name('Librarian').update_attributes(:privilege_tag_id=>PrivilegeTag.find_by_name_tag('administration_operations').id, :priority=>120 )
end

menu_link_present = MenuLink rescue false
unless menu_link_present == false
  academics_category = MenuLinkCategory.find_by_name("academics")

  MenuLink.create(:name=>'library_text',:target_controller=>'library',:target_action=>'index',:higher_link_id=>nil,:icon_class=>'library-icon',:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'library_text')

  higher_link = MenuLink.find_by_name('library_text')

  MenuLink.create(:name=>'manage_books',:target_controller=>'books',:target_action=>'index',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'manage_books')
  MenuLink.create(:name=>'search_book_text',:target_controller=>'library',:target_action=>'search_book',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'search_book_text')
  MenuLink.create(:name=>'return_book',:target_controller=>'book_movement',:target_action=>'return_book',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'return_book')
  MenuLink.create(:name=>'issue_books',:target_controller=>'book_movement',:target_action=>'direct_issue_book',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'issue_books')
  MenuLink.create(:name=>'manage_barcode',:target_controller=>'books',:target_action=>'manage_barcode',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'manage_barcode')
  MenuLink.create(:name=>'library_setting_text',:target_controller=>'library',:target_action=>'card_setting',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'library_setting_text')
  MenuLink.create(:name=>'movement_log_index',:target_controller=>'library',:target_action=>'movement_log',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'movement_log_index')
  MenuLink.create(:name=>'book_renewal',:target_controller=>'book_movement',:target_action=>'renewal',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'book_renewal')
  MenuLink.create(:name=>'manage_book_additional_details',:target_controller=>'books',:target_action=>'add_additional_details',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'manage_book_additional_details')
  MenuLink.create(:name=>'library_fines',:target_controller=>'books',:target_action=>'library_transactions',:higher_link_id=>higher_link.id,:icon_class=>nil,:link_type=>'general',:user_type=>nil,:menu_link_category_id=>academics_category.id) unless MenuLink.exists?(:name=>'library_fines')

end

