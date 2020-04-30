class CreateReminderAttachments < ActiveRecord::Migration
  def self.up
    create_table :reminder_attachments do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :reminder_attachments
  end
end
