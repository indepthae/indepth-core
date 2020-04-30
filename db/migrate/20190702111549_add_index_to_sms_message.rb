class AddIndexToSmsMessage < ActiveRecord::Migration
  def self.up
    add_index :sms_messages, :automated_message, :name => "index_by_automated_message"
    add_index :sms_messages, :message_type, :name => "index_by_message_type"
  end

  def self.down
    remove_index :sms_messages,  :name => "index_by_automated_message"
    remove_index :sms_messages,  :name => "index_by_message_type"
  end
end
