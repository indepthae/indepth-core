finance_transaction_model = ExportStructure.find_by_model_name('finance_transaction')
unless finance_transaction_model.nil?
  finance_transaction_model.query = {"find_in_batches"=>{:include=>[:master_transaction, :payee, :transaction_ledger], :conditions=>{}, :batch_size=>10}}
  finance_transaction_model.save
end