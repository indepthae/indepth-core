if (MultiSchool rescue false)
  School.active.each do |school|
    MultiSchool.current_school=school
    t1=FinanceTransaction.all(:conditions=>["finance_type in (?)",["FinanceFee"]],:joins=>:particular_payments,:readonly=>false)
    t1.each do |t|
      t.update_attribute('trans_type','particular_wise')
    end
    t2=FinanceTransaction.all(:conditions=>["finance_type in (?)",["InstantFee"]])
    t2.each do |t|
      t.update_attribute('trans_type','particular_wise')
    end
  end
else
  t1=FinanceTransaction.all(:conditions=>["finance_type in (?)",["FinanceFee"]],:joins=>:particular_payments,:readonly=>false)
  t1.each do |t|
    t.update_attribute('trans_type','particular_wise')
  end
  t2=FinanceTransaction.all(:conditions=>["finance_type in (?)",["InstantFee"]])
  t2.each do |t|
    t.update_attribute('trans_type','particular_wise')
  end
end