finance_transaction_model = ExportStructure.find_by_model_name('finance_transaction')
unless finance_transaction_model.nil?
  finance_transaction_model.query["find_in_batches"][:conditions] = "(fa.id IS NULL OR fa.is_deleted = false)"
  finance_transaction_model.query["find_in_batches"][:joins] = "LEFT JOIN finance_transaction_receipt_records ftrr ON ftrr.finance_transaction_id = finance_transactions.id LEFT JOIN fee_accounts fa ON fa.id = ftrr.fee_account_id"
  finance_transaction_model.query["find_in_batches"][:include].delete :transaction_ledger
  finance_transaction_model.query["find_in_batches"][:include] += [:transaction_receipt, :finance, :category]
  finance_transaction_model.query["find_in_batches"][:include].uniq!
  finance_transaction_model.send(:update_without_callbacks)
end