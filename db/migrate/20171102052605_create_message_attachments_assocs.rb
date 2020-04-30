class CreateMessageAttachmentsAssocs < ActiveRecord::Migration
  def self.up
    create_table :message_attachments_assocs do |t|
      t.references :message
      t.references :message_attachment
    end
  end

  def self.down
    drop_table :message_attachments_assocs
  end
end
