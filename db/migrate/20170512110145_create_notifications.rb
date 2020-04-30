class CreateNotifications < ActiveRecord::Migration
  def self.up
    create_table :notifications do |t|
      t.text  :content
      t.string  :initiator
      t.timestamps
    end
    
    create_table :notification_recipients do |t|
      t.references  :notification
      t.integer :recipient_id
      t.string  :reference_link
      t.boolean :is_read, :default => false
    end
  end

  def self.down
    drop_table :notifications
    drop_table :notification_recipients
  end
end
