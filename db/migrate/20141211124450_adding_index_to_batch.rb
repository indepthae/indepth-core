class AddingIndexToBatch < ActiveRecord::Migration
  def self.up
    add_index :batches, :is_deleted
    add_index :batches, :is_active
  end

  def self.down
    remove_index :batches, :is_deleted
    remove_index :batches, :is_active
  end
end
