class CreateTableAssignableFoldersFolderAssignmentTypes < ActiveRecord::Migration
  def self.up
    create_table :assignable_folders_folder_assignment_types, :id => false do |t|
      t.references :assignable_folder
      t.references :folder_assignment_type
    end
  end

  def self.down
      drop_table  :assignable_folders_folder_assignment_types
  end
end
