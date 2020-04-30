class AddColumnIsDeletedToClassrooms < ActiveRecord::Migration
  def self.up
    add_column :classrooms, :is_deleted, :boolean
  end

  def self.down
    remove_column :classrooms, :is_deleted
  end
end
