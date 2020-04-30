class CreateMailAttachments < ActiveRecord::Migration
  def self.up
    create_table :mail_attachments do |t|
      t.integer :mail_message_id
      t.string :attachment_file_name
      t.string :attachment_content_type
      t.integer :attachment_file_size
      t.datetime :attachment_updated_at
      t.integer :school_id

      t.timestamps
    end
    add_index :mail_attachments, :mail_message_id
  end

  def self.down
    drop_table :mail_attachments
  end
end
