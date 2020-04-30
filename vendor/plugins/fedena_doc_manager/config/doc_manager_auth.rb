authorization do

  #custom - privileges

  role :document_manager do
    has_permission_on [:folders],
      :to => [
      :create,
      :destroy,
      :favorite,
      :new,
      :edit,
      :update,
      :show,
      :to_employees,
      :to_students,
      :update_course_list,
      :update_dept_list,
      :update_member_list,
      :update_upload_member_list,
      :create_privileged,
      :create_userspecific,
      :edit_privileged,
      :edit_userspecific,
      :new_privileged,
      :new_userspecific,
      :update_privileged,
      :update_userspecific,
      :destroy_privileged
    ]


    has_permission_on [:doc_managers],
      :to => [
      :user_docs,
      :user_docs_ajax,
      :update_userspecific_docs,
      :add_files,
      :add_iframe_files,
      :delete_checked,
      :favorite,
      :favorite_docs,
      :index,
      :my_docs,
      :privileged_docs,
      :recent_docs,
      :save_files,
      :shared_docs,
      :share_docs,
      :search_docs_ajax
    ]
    has_permission_on [:documents],
      :to => [
      :add_document_fields,
      :create,
      :favorite,
      :new,
      :to_employees,
      :to_students,
      :update_member_list,
      :add_privileged_document,
      :create_privileged_docs,
      :edit_privileged_document,
      :download,
      :destroy,
      :update,
      :remove,
      :edit,
    ]
  end

  role :basic_document_manager do
    has_permission_on [:doc_managers],
      :to => [
      :add_files,
      :add_iframe_files,
      :delete_checked,
      :favorite,
      :favorite_docs,
      :index,
      :my_docs,
      :privileged_docs,
      :recent_docs,
      :save_files,
      :shared_docs,
      :share_docs,
      :search_docs_ajax
    ]

    has_permission_on [:folders],
      :to => [
      :create,
      :destroy,
      :favorite,
      :new,
      :to_employees,
      :to_students,
      :update_course_list,
      :update_dept_list,
      :update_member_list,
      :update_upload_member_list
    ]
    has_permission_on [:folders],
      :to => [
        :edit,
        :update,
      ] do
        if_attribute :user_id => is {user.id}
      end
    has_permission_on [:folders],
      :to => [
        :show,
      ] ,:join_by => :or  do
        if_attribute :users => contains { user }
        if_attribute :user_id => is {user.id}
        if_attribute :type =>  'PrivilegedFolder'
      end

    has_permission_on [:documents],
      :to => [
      :add_document_fields,
      :create,
      :favorite,
      :new,
      :to_employees,
      :to_students,
      :update_member_list,
      :add_privileged_document,
      :create_privileged_docs,
      :edit_privileged_document
    ]
    has_permission_on [:documents],
      :to => [
        :update,
        :remove,
        :edit,
      ] do
        if_attribute :user_id => is {user.id}
      end
    has_permission_on [:documents],
      :to => [
        :download,
        :destroy
      ] ,:join_by => :or  do
        if_attribute :users => contains { user }
        if_attribute :user_id => is {user.id}
        if_attribute :folder =>{:users => contains { user }}
        if_attribute :is_public? => true
      end
  end

  role :student do
    includes :basic_document_manager
  end

  role :employee do
    includes :basic_document_manager
  end

  role :admin do
    # includes :basic_document_manager
    includes :document_manager
  end
end
