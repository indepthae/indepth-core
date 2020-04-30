class CreateTableDocumentsUsers < ActiveRecord::Migration
  def self.up
    create_table :documents_users, :id => false do |t|
      t.references :user
      t.references :document
    end
  end

  def self.down
      drop_table  :documents_users
  end
end
