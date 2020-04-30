class AddIndexOnFeeRefund < ActiveRecord::Migration
  def self.up
    add_index :fee_refunds, :finance_fee_id
  end

  def self.down
    remove_index :fee_refunds, :finance_fee_id
  end
end
