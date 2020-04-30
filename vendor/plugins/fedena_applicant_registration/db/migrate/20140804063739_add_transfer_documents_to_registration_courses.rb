class AddTransferDocumentsToRegistrationCourses < ActiveRecord::Migration
  def self.up
    add_column :registration_courses, :transfer_documents, :boolean, :default => false
  end

  def self.down
    remove_column :registration_courses, :transfer_documents
  end
end
