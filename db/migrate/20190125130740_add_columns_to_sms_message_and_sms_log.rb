class AddColumnsToSmsMessageAndSmsLog < ActiveRecord::Migration
  def self.up
    #SmsMessage
    add_column :sms_messages, :group_id, :integer
    add_column :sms_messages, :group_type, :string
    add_column :sms_messages, :message_type, :string, :default => "plain_message"
    add_column :sms_messages, :automated_message, :boolean
    # SmsLog
    add_column :sms_logs, :message, :text 
    add_column :sms_logs, :user_id, :integer 
  end

  def self.down
    #SmsMessage
    remove_column :sms_messages, :group_id
    remove_column :sms_messages, :group_type
    remove_column :sms_messages, :message_type
    remove_column :sms_messages, :automated_message
    # SmsLog
    remove_column :sms_logs, :message
    remove_column :sms_logs, :user_id
  end
end
