class CreateMailLogRecipientLists < ActiveRecord::Migration
  def self.up
    create_table :mail_log_recipient_lists do |t|
      t.text :recipients
      t.integer :mail_log_id
      t.integer :recipients_count, :default => 0
      t.integer :school_id
    
      t.timestamps
    end
    add_index :mail_log_recipient_lists, :mail_log_id
  end

  def self.down
    drop_table :mail_log_recipient_lists
  end
end
