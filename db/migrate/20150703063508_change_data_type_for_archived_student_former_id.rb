class ChangeDataTypeForArchivedStudentFormerId < ActiveRecord::Migration
  def self.up
    change_column :archived_students, :former_id,  :integer
  end

  def self.down
    change_column :archived_students, :former_id,  :string
  end
end
