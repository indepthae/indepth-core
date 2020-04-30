class CreateGrns < ActiveRecord::Migration
  def self.up
    create_table :grns do |t|
      t.string :grn_no
      t.string :invoice_no
      t.datetime :grn_date
      t.datetime :invoice_date
      t.decimal :other_charges, :precision => 10, :scale => 2
      t.boolean :is_deleted, :default => false
      t.references :purchase_order
      t.references :finance_transaction
        
      t.timestamps
    end
  end

  def self.down
    drop_table :grns
  end
end
