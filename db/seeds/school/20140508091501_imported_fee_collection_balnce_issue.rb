a={"FinanceFee Ids and amount to be deduct"=>{}}
   FinanceFee.all.each do |ff|
    student=ff.student
    fee_collection=ff.finance_fee_collection
    batch=ff.batch
       fee_particulars=""
       fee_particulars = fee_collection.finance_fee_particulars.all(:conditions=>"batch_id=#{batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==batch) } if fee_collection and !fee_collection.is_deleted and batch and student
    if  fee_particulars.present?

       discounts=fee_collection.fee_discounts.all(:conditions=>"batch_id=#{batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==batch) }
       actual_amt=fee_particulars.map{|s| s.amount}.sum.to_f
       total_discount =discounts.map{|d| actual_amt * d.discount.to_f/(d.is_amount? ? actual_amt : 100)}.sum.to_f unless discounts.nil?
       actual_amt=actual_amt-total_discount
       paid_amount=0
       ff.finance_transactions.each{|s| paid_amount=paid_amount+(s.amount-s.fine_amount)}
       current_amt=ff.balance.to_f+(paid_amount.to_f)
       unless current_amt == actual_amt
         if current_amt > actual_amt
         deduct_amt=current_amt-actual_amt
         if ff.balance.to_f >= deduct_amt.to_f
           bal =ff.balance.to_f-deduct_amt.to_f
           # bal= (bal.is_a?(Float) && bal.nan?) ? 0 : bal
           ff.update_attributes(:balance=>"#{bal}") unless (bal.is_a?(Float) && bal.nan?)
         else

           a["FinanceFee Ids and amount to be deduct"].merge!({ff.id=>{'amount_to_deduct'=>deduct_amt.to_f}})


         end
         else
           amount_to_be_added=ff.balance.to_f+actual_amt.to_f-current_amt.to_f
           amount_to_be_added= (amount_to_be_added.is_a?(Float) && amount_to_be_added.nan?) ? 0 : amount_to_be_added
           ff.update_attributes(:balance=>"#{amount_to_be_added.to_f}",:is_paid=>false)
         end
       end
    end
   end
   File.open("#{RAILS_ROOT}/log/corrupted_financefees.yml", "a+") { |f| f.write a.to_yaml}