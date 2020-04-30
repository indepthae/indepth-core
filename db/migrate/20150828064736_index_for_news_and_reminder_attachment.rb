class IndexForNewsAndReminderAttachment < ActiveRecord::Migration
  def self.up
    add_index(:reminder_attachment_relations, [:reminder_id, :reminder_attachment_id], :unique => true,:name=>:reminder_attachment_index)
    add_index(:news_attachments, :news_id)
  end

  def self.down
    remove_index(:reminder_attachment_relations, [:reminder_id, :reminder_attachment_id], :unique => true,:name=>:reminder_attachment_index)
    remove_index(:news_attachments, :news_id)
  end
end
