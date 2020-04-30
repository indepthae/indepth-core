class RenameCollctionToFeecollectionInFinancePayment < ActiveRecord::Migration
  def self.up
    rename_column :finance_payments, :collection_type, :fee_collection_type
    rename_column :finance_payments, :collection_id, :fee_collection_id
  end

  def self.down
    rename_column :finance_payments, :fee_collection_type,:collection_type
    rename_column :finance_payments,:fee_collection_type,:collection_type
  end
end
