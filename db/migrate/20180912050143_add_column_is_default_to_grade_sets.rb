class AddColumnIsDefaultToGradeSets < ActiveRecord::Migration
  def self.up
    add_column :grade_sets, :is_default, :boolean, :default => false
  end

  def self.down
    remove_column :grade_sets, :is_default
  end
end
