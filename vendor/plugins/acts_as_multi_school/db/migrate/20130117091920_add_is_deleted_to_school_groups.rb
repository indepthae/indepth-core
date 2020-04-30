class AddIsDeletedToSchoolGroups < ActiveRecord::Migration
  def self.up
    add_column :school_groups, :is_deleted, :boolean, :default=>false
  end

  def self.down
    remove_column :school_groups, :is_deleted
  end
end
