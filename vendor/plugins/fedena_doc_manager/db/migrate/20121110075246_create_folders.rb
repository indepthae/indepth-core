class CreateFolders < ActiveRecord::Migration
  def self.up
    create_table :folders do |t|
      t.string :name
      t.references :user
      t.string :type, :length => 30
      t.boolean :is_favorite, :default=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :folders
  end
end
