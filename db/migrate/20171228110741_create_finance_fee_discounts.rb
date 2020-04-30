class CreateFinanceFeeDiscounts < ActiveRecord::Migration
  def self.up
    create_table :finance_fee_discounts do |t|
      t.references :finance_fee_particular, :null => false
      t.references :finance_fee, :null => false
      t.references :fee_discount, :null => false
      t.decimal :discount_amount, :precision => 15, :scale => 4

      t.timestamps
    end
  end

  def self.down
    drop_table :finance_fee_discounts
  end
end
