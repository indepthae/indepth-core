particular_finance_fees=FinanceFee.find(:all,:joins=>{:finance_fee_collection=>{:collection_particulars=>:finance_fee_particular}},:conditions=>"finance_fee_particulars.receiver_type='Batch' and finance_fee_particulars.receiver_id<>finance_fee_particulars.batch_id").uniq
particular_finance_fees.each do |part_fee|
  batch=part_fee.batch
  date=part_fee.finance_fee_collection
  student=part_fee.student
  fee_particulars = date.finance_fee_particulars.all(:conditions=>"batch_id=#{batch.id} and receiver_type='Batch' and receiver_id<>batch_id")
  amount=0.to_f
 
  fee_particulars.each do |fp|
    amount=amount+fp.amount.to_f
    FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `receiver_id` = `batch_id` WHERE (`id`='#{fp.id}' );")
    #fp.update_attributes(:receiver_id=>"#{fp.batch_id}")
  end
 
  balance=part_fee.balance.to_f+amount.to_f
  FinanceFee.connection.execute("UPDATE `finance_fees` SET `balance` = '#{balance}' WHERE (`id`='#{part_fee.id}' );")
end

discount_finance_fees=FinanceFee.find(:all,:joins=>{:finance_fee_collection=>{:collection_discounts=>:fee_discount}},:conditions=>"fee_discounts.receiver_type='Batch' and fee_discounts.receiver_id<>fee_discounts.batch_id").uniq
discount_finance_fees.each do |disc_fee|
  batch=disc_fee.batch
  date=disc_fee.finance_fee_collection
  student=disc_fee.student
  fee_particulars = date.finance_fee_particulars.all(:conditions=>"batch_id=#{batch.id}").select{|par|  (par.receiver.present?) and (par.receiver==student or par.receiver==student.student_category or par.receiver==batch) }
  total_payable=fee_particulars.map{|s| s.amount}.sum.to_f
  discounts=date.fee_discounts.all(:conditions=>"batch_id=#{batch.id} and receiver_type='Batch' and receiver_id<>batch_id")
  total_discount =discounts.map{|d| total_payable * d.discount.to_f/(d.is_amount? ? total_payable : 100)}.sum.to_f unless discounts.nil?
  discounts.each do |fd|
    FeeDiscount.connection.execute("UPDATE `fee_discounts` SET `receiver_id` = `batch_id` WHERE (`id`='#{fd.id}');")
  end
  FinanceFee.connection.execute("UPDATE `finance_fees` SET `balance` = '#{disc_fee.balance.to_f-total_discount}' WHERE (`id`='#{disc_fee.id}' );")
  disc_fee.update_attributes(:balance=>"#{disc_fee.balance.to_f-total_discount}")
end


#FinanceFeeParticular.connection.execute("UPDATE `finance_fee_particulars` SET `receiver_id` = `batch_id` WHERE (`receiver_type`='Batch' AND  `receiver_id` <> `batch_id`);")
#FeeDiscount.connection.execute("UPDATE `fee_discounts` SET `receiver_id` = `batch_id` WHERE (`receiver_type`='Batch' AND  `receiver_id` <> `batch_id`);")