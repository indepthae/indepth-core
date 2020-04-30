FinanceTransaction.find(:all, :select => "distinct finance_transactions.*", :joins => "left join particular_payments pp on pp.finance_transaction_id=finance_transactions.id", :conditions => "pp.id is null and finance_transactions.finance_type='FinanceFee'").each do |ft|
  allocate_amount_to_particulars=AllocateAmountToParticulars.new(ft, ft.finance)
  allocate_amount_to_particulars.save_allocation
end