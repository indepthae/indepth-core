class CreateIndicesForUsers < ActiveRecord::Migration
  def self.up
    add_index :users,:student
    add_index :users,:admin
    add_index :users,:employee
    add_index :users,:parent
    add_index :users,:is_deleted
  end

  def self.down
    remove_index :users,:student
    remove_index :users,:admin
    remove_index :users,:employee
    remove_index :users,:parent
    remove_index :users,:is_deleted
  end
end
