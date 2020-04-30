FeeCollectionBatch.all.each do |fcb|
    date=fcb.finance_fee_collection
    p=date.finance_fee_particulars.all(:conditions=>"batch_id=#{fcb.batch_id}")
    fcb.destroy unless p.present?
  end