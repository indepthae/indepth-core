class CreateStores < ActiveRecord::Migration
  def self.up
    create_table :stores do |t|
      t.string :name
      t.string :code
      t.boolean :is_deleted, :default => false
      t.references :store_category
      t.references :store_type

      t.timestamps
    end
  end

  def self.down
    drop_table :stores
  end
end
