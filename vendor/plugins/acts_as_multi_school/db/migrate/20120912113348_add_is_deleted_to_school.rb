class AddIsDeletedToSchool < ActiveRecord::Migration
  def self.up
    add_column :schools, :is_deleted, :boolean, :default => false
  end

  def self.down
    remove_column :schools, :is_deleted
  end
end
