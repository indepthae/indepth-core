class AddingNewColumnToArchivedGuardian < ActiveRecord::Migration
  def self.up
    add_column :archived_guardians, :former_user_id, :integer
    add_column :archived_guardians, :former_id,:integer
  end

  def self.down
    remove_column :archived_guardians, :former_user_id
    remove_column :archived_guardians, :former_id
  end
end
