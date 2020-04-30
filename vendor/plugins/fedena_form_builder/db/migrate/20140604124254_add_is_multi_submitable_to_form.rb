class AddIsMultiSubmitableToForm < ActiveRecord::Migration
  def self.up
    add_column :forms, :is_multi_submitable, :boolean, :default => false
  end

  def self.down
    remove_column :forms, :is_multi_submitable
  end
end
