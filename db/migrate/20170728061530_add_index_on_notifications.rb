class AddIndexOnNotifications < ActiveRecord::Migration
  def self.up
    add_index :notification_recipients, :notification_id, :name => "index_on_notification_id"
    add_index :notification_recipients, :recipient_id, :name => 'index_on_recipient_id'
    add_index :notifications, :initiator, :name => "index_on_type"
  end

  def self.down
    remove_index :notification_recipients, :name=>"index_on_notification_id"
    remove_index :notification_recipients, :name=>"index_on_recipient_id"
    remove_index :notifications, :name=>"index_on_type"
  end
end
