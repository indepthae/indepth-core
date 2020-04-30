class CreateFolderAssignmentTypes < ActiveRecord::Migration
  def self.up
    create_table :folder_assignment_types do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :folder_assignment_types
  end
end
