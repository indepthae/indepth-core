class ChangeColumnOfNotification < ActiveRecord::Migration
  def self.up
    add_column :notifications,  :payload, :text
    remove_column :notification_recipients,  :reference_link
    remove_column :message_recipients, :recipient_type
  end

  def self.down
    remove_column :notifications,  :reference_link
  end
end
