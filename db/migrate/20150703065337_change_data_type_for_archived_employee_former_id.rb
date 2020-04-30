class ChangeDataTypeForArchivedEmployeeFormerId < ActiveRecord::Migration
  def self.up
    change_column :archived_employees, :former_id,  :integer
    add_index :archived_employees, :former_id
  end

  def self.down
    change_column :archived_employees, :former_id,  :string
    remove_index :archived_employees, :former_id
  end
end
