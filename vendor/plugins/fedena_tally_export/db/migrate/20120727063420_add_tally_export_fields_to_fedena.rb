class AddTallyExportFieldsToFedena < ActiveRecord::Migration
  def self.up
    add_column :finance_transactions, :lastvchid, :integer
    add_column :finance_transaction_categories, :tally_ledger_id, :integer
  end

  def self.down
  end
end
