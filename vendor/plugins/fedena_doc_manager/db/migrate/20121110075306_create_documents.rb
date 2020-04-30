class CreateDocuments < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      t.string :name
      t.references :user
      t.boolean :is_deleted
      t.references :folder
      t.boolean :is_favorite, :default=>false

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
