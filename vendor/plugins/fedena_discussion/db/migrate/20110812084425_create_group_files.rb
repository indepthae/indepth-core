class CreateGroupFiles < ActiveRecord::Migration
  def self.up
    create_table :group_files do |t|
      t.references :group
      t.references :user
      t.string :file_description
      t.references :group_post

      t.timestamps
    end
  end

  def self.down
    drop_table :group_files
  end
end
