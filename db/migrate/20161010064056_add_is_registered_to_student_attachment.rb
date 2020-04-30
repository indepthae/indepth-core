class AddIsRegisteredToStudentAttachment < ActiveRecord::Migration
  def self.up
    add_column :student_attachments, :is_registered, :boolean, :default => false
  end

  def self.down
    remove_column :student_attachments, :is_registered
  end
end
