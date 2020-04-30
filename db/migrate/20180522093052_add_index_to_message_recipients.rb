class AddIndexToMessageRecipients < ActiveRecord::Migration
  def self.up
    add_index :message_recipients, [:recipient_id, :is_deleted, :is_read], :name => "index_on_recipient_id__and_is_deleted_and_is_read"
  end

  def self.down
    remove_index :message_recipients, :name => "index_on_recipient_id__and_is_deleted_and_is_read"
  end
end
