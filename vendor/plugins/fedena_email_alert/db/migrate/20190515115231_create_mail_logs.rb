class CreateMailLogs < ActiveRecord::Migration
  def self.up
    create_table :mail_logs do |t|
      t.string :subject
      t.text :body
      t.string :type
      t.integer :mail_message_id
      t.string :sender_mail_id
      t.integer :sender_id
      t.string :alert_record_type
      t.integer :alert_record_id
      t.string :alert_event
      t.integer :school_id

      t.timestamps
    end
    add_index :mail_logs, [:school_id, :type]
  end

  def self.down
    drop_table :mail_logs
  end
end
