class AddIsEditableToForms < ActiveRecord::Migration
  def self.up
    add_column :forms, :is_editable, :boolean, :default => false
  end

  def self.down
    remove_column :forms, :is_editable
  end
end
