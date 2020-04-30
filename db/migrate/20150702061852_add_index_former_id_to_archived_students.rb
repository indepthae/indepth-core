class AddIndexFormerIdToArchivedStudents < ActiveRecord::Migration
  def self.up
    add_index :archived_students, :former_id
  end

  def self.down
    remove_index :archived_students, :former_id
  end
end
