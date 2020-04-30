class AddIsTargetedToForm < ActiveRecord::Migration
  def self.up
    add_column :forms, :is_targeted, :boolean
  end

  def self.down
    remove_column :forms, :is_targeted
  end
end