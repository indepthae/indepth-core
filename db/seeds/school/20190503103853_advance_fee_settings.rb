[
  {"config_key" => "AdvanceFeePaymentForStudent"     ,"config_value" => "0"}
].each do |param|
  Configuration.find_or_create_by_config_key_and_config_value(param)
end
    
[
  {"name" => 'Advance Fees Credit'  ,"description" => ' ',"is_income" => true},
  {"name" => 'Advance Fees Debit'  ,"description" => ' ',"is_income" => false}
].each do |param|
  FinanceTransactionCategory.find_or_create_by_name(param)
end