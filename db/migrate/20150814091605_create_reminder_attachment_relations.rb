class CreateReminderAttachmentRelations < ActiveRecord::Migration
  def self.up
    create_table :reminder_attachment_relations do |t|
      t.references :reminder
      t.references :reminder_attachment

      t.timestamps
    end
  end

  def self.down
    drop_table :reminder_attachment_relations
  end
end
