class CreateIndentItems < ActiveRecord::Migration
  def self.up
    create_table :indent_items do |t|
      t.integer :quantity
      t.string :batch_no
      t.integer :pending
      t.integer :issued
      t.string :issued_type
      t.decimal :price, :precision => 10, :scale => 2
      t.integer :required
      t.boolean :is_deleted,:default => false
      t.references :indent
      t.references :store_item

      t.timestamps
    end
  end

  def self.down
    drop_table :indent_items
  end
end
