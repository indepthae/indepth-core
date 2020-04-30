class AddingIndexToFinanceFee < ActiveRecord::Migration
  def self.up
    add_index :finance_fees,:balance
  end

  def self.down
    remove_index :finance_fees,:balance
  end
end
