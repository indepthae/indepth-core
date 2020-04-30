class CreateDocumentUsers < ActiveRecord::Migration
  def self.up
    create_table :document_users do |t|
      t.references :user
      t.references :document
      t.boolean :is_favorite, :default=>false
      
      t.timestamps
    end
  end

  def self.down
    drop_table :document_users
  end
end
