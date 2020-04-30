class AddIsParentToForm < ActiveRecord::Migration
  def self.up
    add_column :forms, :is_parent, :integer, :default => 1
  end

  def self.down
    remove_column :forms, :is_parent
  end
end
