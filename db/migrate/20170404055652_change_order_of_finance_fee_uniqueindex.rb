class ChangeOrderOfFinanceFeeUniqueindex < ActiveRecord::Migration
  def self.up
    unless (ActiveRecord::Base.connection.execute("SHOW INDEX FROM finance_fees WHERE Key_name = 'finance_fee_uniqueness';").all_hashes.empty?)
      remove_index :finance_fees,:name=>:finance_fee_uniqueness
    end
    add_index :finance_fees, [:student_id,:fee_collection_id], :unique=> true,:name=>:finance_fee_uniqueness
  end

  def self.down
    remove_index :finance_fees,:name=>:finance_fee_uniqueness
  end
end
