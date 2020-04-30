class AddParticularPaymentUniquenessIndex < ActiveRecord::Migration
  def self.up
    if (ActiveRecord::Base.connection.execute("SHOW INDEX FROM particular_payments WHERE Key_name = 'particular_payment_uniqueness';").all_hashes.empty?)
      add_index :particular_payments, [:finance_fee_particular_id,:finance_transaction_id], :unique=> true,:name=>:particular_payment_uniqueness
    end
  end

  def self.down
    remove_index :particular_payments,:name=>:particular_payment_uniqueness
  end
end
