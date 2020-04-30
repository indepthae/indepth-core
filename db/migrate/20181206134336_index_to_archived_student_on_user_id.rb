class IndexToArchivedStudentOnUserId < ActiveRecord::Migration
  def self.up
    add_index :archived_students, :user_id
  end

  def self.down
    remove_index :archived_students, :user_id
  end
end
