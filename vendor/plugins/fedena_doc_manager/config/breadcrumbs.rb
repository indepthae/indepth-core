Gretel::Crumbs.layout do

  crumb :doc_managers_index do
    link I18n.t('doc_managers.doc_manager'), {:controller=>"doc_managers",:action=>"index"}
  end

  crumb :documents_new do
    link I18n.t('documents.add_file'), {:controller=>"documents",:action=>"new"}
    parent :doc_managers_index
  end

  crumb :documents_create do
    link I18n.t('documents.add_file'), {:controller=>"documents",:action=>"create"}
    parent :doc_managers_index
  end

  crumb :documents_edit do
    link I18n.t('documents.edit_shareable_document'), {:controller=>"documents",:action=>"edit"}
    parent :doc_managers_index
  end

  crumb :documents_update do
    link I18n.t('documents.edit_shareable_document'), {:controller=>"documents",:action=>"update"}
    parent :doc_managers_index
  end

  crumb :doc_managers_share_docs do
    link I18n.t('doc_managers.share'), {:controller=>"doc_managers",:action=>"share_docs"}
    parent :doc_managers_index
  end

  crumb :documents_add_privileged_document do
    link I18n.t('documents.create_privileged_document'), {:controller=>"documents",:action=>"add_privileged_document"}
    parent :doc_managers_index
  end

  crumb :documents_edit_privileged_document do
    link I18n.t('documents.edit_privileged_document'), {:controller=>"documents",:action=>"edit_privileged_document"}
    parent :doc_managers_index
  end

  crumb :folders_new do
    link I18n.t('folders.make_shareable_folder'), {:controller=>"folders",:action=>"new"}
    parent :doc_managers_index
  end

  crumb :folders_create do
    link I18n.t('folders.make_shareable_folder'), {:controller=>"folders",:action=>"create"}
    parent :doc_managers_index
  end

  crumb :folders_edit do
    link I18n.t('folders.edit_shareable'), {:controller=>"folders",:action=>"edit"}
    parent :doc_managers_index
  end

  crumb :folders_update do
    link I18n.t('folders.edit_shareable'), {:controller=>"folders",:action=>"update"}
    parent :doc_managers_index
  end

  crumb :folders_edit_privileged do
    link I18n.t('folders.edit_privileged_folder'), {:controller=>"folders",:action=>"edit_privileged"}
    parent :doc_managers_index
  end

  crumb :folders_update_privileged do
    link I18n.t('folders.edit_privileged_folder'), {:controller=>"folders",:action=>"update_privileged"}
    parent :doc_managers_index
  end

  crumb :folders_new_privileged do
    link I18n.t('folders.make_privileged_folder'), {:controller=>"folders",:action=>"new_privileged"}
    parent :doc_managers_index
  end

  crumb :folders_create_privileged do
    link I18n.t('folders.make_privileged_folder'), {:controller=>"folders",:action=>"create_privileged"}
    parent :doc_managers_index
  end

  crumb :folders_new_userspecific do
    link I18n.t('folders.make_userspecific_folder'), {:controller=>"folders",:action=>"new_userspecific"}
    parent :doc_managers_index
  end

  crumb :folders_create_userspecific do
    link I18n.t('folders.make_userspecific_folder'), {:controller=>"folders",:action=>"create_userspecific"}
    parent :doc_managers_index
  end

  crumb :folders_edit_userspecific do
    link I18n.t('folders.edit_userspecific_folder'), {:controller=>"folders",:action=>"edit_userspecific"}
    parent :doc_managers_index
  end

  crumb :folders_update_userspecific do
    link I18n.t('folders.edit_userspecific_folder'), {:controller=>"folders",:action=>"update_userspecific"}
    parent :doc_managers_index
  end
end