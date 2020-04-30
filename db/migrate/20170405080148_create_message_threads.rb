class CreateMessageThreads < ActiveRecord::Migration
  def self.up
    create_table :message_threads do |t|
      t.text  :subject
      t.integer :creator_id
      t.boolean :can_reply, :default => true
      t.boolean :is_deleted, :default => false
      t.boolean :is_group_message, :default => false
      t.timestamps
    end
    
    create_table :messages do |t|
      t.text :body
      t.integer :sender_id
      t.references  :message_thread
      t.boolean :is_deleted, :default => false
      t.boolean :is_primary, :default => false
      t.boolean :is_to_all, :default => false
      t.timestamps
    end
    
    create_table :message_recipients do |t|
      t.references  :message
      t.integer :recipient_id
      t.string :recipient_type
      t.integer :thread_id
      t.boolean :is_read, :default  => false
      t.boolean :is_deleted, :default => false
      t.timestamps
    end
    
    create_table :message_attachments do |t|
      t.references  :message
      t.string  :attachment_file_name
      t.string  :attachment_content_type
      t.string  :attachment_file_size
      t.datetime  :attachment_updated_at
      t.timestamps
    end
  end

  def self.down
    drop_table :message_threads
    drop_table :messages
    drop_table :message_recipients
    drop_table :message_attachments
  end
end
