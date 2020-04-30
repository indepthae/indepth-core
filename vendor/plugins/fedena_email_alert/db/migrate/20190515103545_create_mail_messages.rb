class CreateMailMessages < ActiveRecord::Migration
  def self.up
    create_table :mail_messages do |t|
      t.string :subject
      t.text :body
      t.integer :sender_id
      t.boolean :has_template, :default => false
      t.text :additional_info
      t.integer :school_id

      t.timestamps
    end

    add_index :mail_messages, :school_id
  end

  def self.down
    drop_table :mail_messages
  end
end
