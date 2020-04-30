class AddIndexOnMessagesMessageThread < ActiveRecord::Migration
  def self.up
    add_index :messages, :message_thread_id, :name => "index_on_message_id"
    add_index :message_recipients, :message_id, :name=>"index_on_recipients"
    add_index :message_attachments, :message_id, :name=>"index_attachments"
    add_index :notification_recipients, :notification_id, :name=>'index_notification'
  end

  def self.down
    remove_index :messages, :name => "index_on_message_id"
    remove_index :message_recipients, :name=>"index_o_recipients"
    remove_index :message_attachments, :name=>"index_attachments"
    remove_index :notification_recipients, :name=>'index_notification'
  end
end