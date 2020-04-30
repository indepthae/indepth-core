class CreateSoldItems < ActiveRecord::Migration
  def self.up
    create_table :sold_items do |t|
      t.references :store_item
      t.references :invoice
      t.integer :quantity
      t.string :code
      t.string :invoice_type
      t.decimal :rate, :precision =>15, :scale => 2
      t.timestamps
    end
  end

  def self.down
    drop_table :sold_items
  end
end
