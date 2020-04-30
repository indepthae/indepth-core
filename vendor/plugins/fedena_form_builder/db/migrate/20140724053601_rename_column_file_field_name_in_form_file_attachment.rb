class RenameColumnFileFieldNameInFormFileAttachment < ActiveRecord::Migration
  def self.up
    rename_column :form_file_attachments, :form_file_field_id, :form_field_file_id
  end

  def self.down
    rename_column :form_file_attachments, :form_field_file_id, :form_file_field_id
  end
end
