class CreateMailRecipientLists < ActiveRecord::Migration
  def self.up
    create_table :mail_recipient_lists do |t|
      t.integer :mail_message_id
      t.string :recipient_type
      t.text :recipient_ids
      t.integer :school_id

      t.timestamps
    end

    add_index :mail_recipient_lists, :mail_message_id
  end

  def self.down
    drop_table :mail_recipient_lists
  end
end
