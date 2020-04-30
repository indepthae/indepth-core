ActionController::Routing::Routes.draw do |map|

  map.resources :documents, :member => {
    :remove => [:post],
    :download => [:get]
  },
    :collection => {
    :to_employees => [:post,:get],
    :update_member_list => [:post],
    :add_document_fields => [:post],
    :add_privileged_document => [:post],
    :edit_privileged_document => [:post, :get]
  }
    
  map.resources :folders,:except=>[:show], :collection => {
    :favorite => [:post,:get],
    :to_employees => [:post,:get],
    :to_students => [:post, :get],
    :update_course_list => [:post,:get],
    :update_dept_list => [:post,:get],
    :update_member_list => [:post],
    :update_upload_member_list  => [:post,:get]
  }

  map.resources :doc_managers, :collection => {
    :add_files => [:post],
    :add_iframe_files => [:post,:get],
    :delete_checked=>[:post],
    :favorite_docs => [:post],
    :my_docs => [:post],
    :privileged_docs => [:post],
    :recent_docs => [:post],
    :shared_docs => [:post],
    :share_docs=>[:get],
    :search_docs_ajax => [:post],
    :update_userspecific_docs=>[:post],
    :user_docs => [:post]
  }
  
  map.add_privileged_document 'folders/:id/documents/new', :controller => "documents", :action => "add_privileged_document"
  map.create_privileged_document 'folders/:id/documents/new', :controller => "documents", :action => "create_privileged_docs"
  map.edit_privileged_document 'folders/:id/documents/edit', :controller => "documents", :action => "edit_privileged_document"
  map.new_shareable_folder 'folders/shareable/new', :controller => "folders", :action => "new", :folder_type => 'shareable'
  map.new_userspecific_folder 'folders/userspecific/new', :controller => "folders", :action => "new_userspecific", :folder_type => 'userspecific'
  map.new_privileged_folder 'folders/privileged/new', :controller => "folders", :action => "new_privileged", :folder_type => 'privileged'
  map.create_folder 'folders/shareable', :controller => "folders", :action => "create", :folder_type => 'shareable'
  map.create_userspecific_folder 'folders/userspecific', :controller => "folders", :action => "create_userspecific", :folder_type => 'userspecific'
  map.create_privileged_folder 'folders/privileged', :controller => "folders", :action => "create_privileged", :folder_type => 'privileged'
  map.edit_shareable_folder 'folders/shareable/edit/:id', :controller => "folders", :action => "edit", :folder_type => 'shareable'
  map.edit_userspecific_folder 'folders/userspecific/edit/:id', :controller => "folders", :action => "edit_userspecific", :folder_type => 'userspecific'
  map.edit_privileged_folder 'folders/privileged/edit/:id', :controller => "folders", :action => "edit_privileged", :folder_type => 'privileged'
  map.update_shareable_folder 'folders/shareable/:id', :controller => "folders", :action => "update", :folder_type => 'shareable'
  map.update_userspecific_folder 'folders/userspecific/:id', :controller => "folders", :action => "update_userspecific", :folder_type => 'userspecific'
  map.update_privileged_folder 'folders/privileged/:id', :controller => "folders", :action => "update_privileged", :folder_type => 'privileged'
  map.show_folder 'folders/show/:id', :controller => "folders", :action => "show"
  map.destroy_folder 'folders/destroy/:id', :controller => "folders", :action => "destroy"
  map.destroy_privileged_folder 'folders/destroy_privileged/:id', :controller => "folders", :action => "destroy_privileged"
  
end