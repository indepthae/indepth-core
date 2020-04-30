if (MultiSchool rescue false)
  School.active.each do |school|
    MultiSchool.current_school=school
    category_id=FinanceTransactionCategory.find_by_name('Salary').id
    trans_id=MonthlyPayslip.all.collect(&:finance_transaction_id).uniq.compact
    FinanceTransaction.all(:conditions=>["id NOT IN (?) and category_id = ?",trans_id,category_id]).each do |e|
      e.delete
    end
  end
else
  category_id=FinanceTransactionCategory.find_by_name('Salary').id
  trans_id=MonthlyPayslip.all.collect(&:finance_transaction_id).uniq.compact
  FinanceTransaction.all(:conditions=>["id NOT IN (?) and category_id = ?",trans_id,category_id]).each do |e|
    e.delete
  end
end