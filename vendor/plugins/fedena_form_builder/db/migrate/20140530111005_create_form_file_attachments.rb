class CreateFormFileAttachments < ActiveRecord::Migration
  def self.up
    create_table :form_file_attachments do |t|
      t.integer :form_file_field_id

      t.timestamps
    end
  end

  def self.down
    drop_table :form_file_attachments
  end
end
