class AddIndicesToFinanceFeeDiscount < ActiveRecord::Migration
  def self.up
    add_index :finance_fee_discounts, [:finance_fee_id, :finance_fee_particular_id, :fee_discount_id], :name => "index_by_fee_id_and_particular_id_and_discount_id"
    add_index :finance_fee_discounts, [:finance_fee_id, :fee_discount_id], :name => "index_by_fee_id_and_discount_id"
    add_index :finance_fee_discounts, :finance_fee_particular_id
  end

  def self.down
    remove_index :finance_fee_discounts, :finance_fee_particular_id
    remove_index :finance_fee_discounts, [:finance_fee_id, :fee_discount_id], :name => "index_by_fee_id_and_discount_id" 
    remove_index :finance_fee_discounts, [:finance_fee_id, :finance_fee_particular_id, :fee_discount_id], :name => "index_by_fee_id_and_particular_id_and_discount_id"
  end
end
