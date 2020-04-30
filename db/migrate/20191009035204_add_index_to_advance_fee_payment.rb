class AddIndexToAdvanceFeePayment < ActiveRecord::Migration
  def self.up
    add_index :advance_fee_category_batches, [:advance_fee_category_id, :batch_id, :is_active],  :name => "index_on_a_f_c_id_and_batch_id_and_is_active"
    add_index :advance_fee_categories, [:financial_year_id, :online_payment_enabled, :is_enabled, :is_deleted],  :name => "index_on_f_y_id_and_o_p_enabled_and_is_enabled_and_is_deleted"
    add_index :advance_fee_collections, [:student_id],  :name => "index_on_student_id"
    add_index :advance_fee_deductions, [:student_id, :finance_transaction_id],  :name => "index_on_student_id_and_finance_transaction_id"
    add_index :advance_fee_wallets, [:student_id],  :name => "index_on_student_id"
  end

  def self.down
    remove_index :advance_fee_category_batches, [:advance_fee_category_id, :batch_id, :is_active]
    remove_index :advance_fee_categories, [:financial_year_id, :online_payment_enabled, :is_enabled, :is_deleted]
    remove_index :advance_fee_collections, [:student_id]
    remove_index :advance_fee_deductions, [:student_id, :finance_transaction_id]
    remove_index :advance_fee_wallets, [:student_id]
  end
end
