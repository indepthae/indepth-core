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
ActionController::Routing::Routes.draw do |map|

  map.resources :books,:collection => {:manage_barcode =>[:get,:post,:put],:add_additional_details => [:get,:post,:put],:edit_additional_details => [:get,:post,:put],:additional_data => [:get,:post],:edit_additional_data => [:get,:post,:put],:library_transactions=>[:get,:post], :manage_books_csv_export=>[:get,:post],:generate_library_fine_receipt_pdf=>[:get,:post],:generate_library_fine_receipt=>[:get,:post],:get_library_fine_details=>[:get,:post]},:member => {:change_field_priority => [:get,:post],:delete_additional_details => [:get,:post,:put]}
  map.resources :tags, :collection => {:index => [:get]}, :member => {:show => [:get,:post]}
  map.namespace(:api) do |api|
    api.resources :books
  end
end
