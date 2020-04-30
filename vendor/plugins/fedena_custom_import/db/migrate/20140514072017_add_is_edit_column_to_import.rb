class AddIsEditColumnToImport < ActiveRecord::Migration
  def self.up
    add_column :imports, :is_edit, :boolean, :default => false
  end

  def self.down
    remove_column :imports, :is_edit
  end
end
