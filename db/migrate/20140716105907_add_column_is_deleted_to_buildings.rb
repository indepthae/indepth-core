class AddColumnIsDeletedToBuildings < ActiveRecord::Migration
  def self.up
    add_column :buildings, :is_deleted, :boolean
  end

  def self.down
    remove_column :buildings, :is_deleted
  end
end
