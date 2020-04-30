class AddIndexForFinanceFeeIdOfParticularPayment < ActiveRecord::Migration
  def self.up
    add_index :particular_payments , :finance_fee_id
  end

  def self.down
    remove_index :particular_payments , :finance_fee_id
  end
end
