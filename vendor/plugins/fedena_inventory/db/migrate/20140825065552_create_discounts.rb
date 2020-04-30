class CreateDiscounts < ActiveRecord::Migration
  def self.up
    create_table :discounts do |t|
      t.string :name
      t.decimal :amount ,:precision =>15, :scale => 2
      t.references :invoice
      t.string :invoice_type
      t.timestamps
    end
  end

  def self.down
    drop_table :discounts
  end
end
