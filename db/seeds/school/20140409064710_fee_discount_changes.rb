 FeeCollectionDiscount.all.group_by(&:finance_fee_collection_id).each do |k,v|
     CollectionDiscount.destroy_all(:finance_fee_collection_id=>k)
     v.each do |discount|
    dis=FeeDiscount.find(:first,:conditions=>{:finance_fee_category_id=>discount.finance_fee_collection.try('fee_category_id'),:name=>discount.name,:receiver_type=>discount.type.gsub("FeeCollectionDiscount",""),:receiver_id=>discount.receiver_id})

    unless dis
      attr=discount.attributes
      attr.delete "finance_fee_collection_id"
      dis=FeeDiscount.new(attr)
      dis.finance_fee_category_id=discount.finance_fee_collection.try('fee_category_id')
      dis.receiver_type=discount.type.gsub("FeeCollectionDiscount","")
      dis.batch_id=discount.finance_fee_collection.try('batch_id')
      dis.is_deleted=true
      dis.save(false)
    end
    CollectionDiscount.create(:fee_discount_id=>dis.id,:finance_fee_collection_id=>discount.finance_fee_collection_id) if dis
  end
end