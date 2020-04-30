Payment.all.each do |p|
  if p.fee_collection.nil?
    if p.payment_type == "FinanceFee"
      p.update_attributes(:fee_collection => p.finance_transaction.try(:finance).try(:finance_fee_collection))
    elsif p.payment_type == "HostelFee"
      p.update_attributes(:fee_collection => p.finance_transaction.try(:finance).try(:hostel_fee_collection))
    elsif p.payment_type == "TransportFee"
      p.update_attributes(:fee_collection => p.finance_transaction.try(:finance).try(:transport_fee_collection))
    end
  end

  if p.amount.nil?
    amount = p.finance_transaction.nil? ? "" : p.finance_transaction.amount
    p.update_attributes(:amount => amount)
  end

end
