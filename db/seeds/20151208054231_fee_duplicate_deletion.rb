cd_with_school_ids=CollectionDiscount.find_by_sql("SELECT distinct school_id as s_id FROM `collection_discounts` GROUP BY finance_fee_collection_id,fee_discount_id HAVING count(collection_discounts.id)>1;")
cd_with_school_ids.each do |cd_with_school_id|
  MultiSchool.current_school=School.find(cd_with_school_id.s_id)
  CollectionDiscount.find(:all,:select=>"collection_discounts.*,group_concat(id) as all_ids",:group=>"finance_fee_collection_id,fee_discount_id",:having=>"count(collection_discounts.id)>1").each do |cd|
    delete_ids=cd.all_ids.split(',').map{|f| f.to_i}-[cd.id]


    fc=FinanceFeeCollection.find(cd.finance_fee_collection_id)
    fd=FeeDiscount.find(cd.fee_discount_id)
    CollectionDiscount.destroy_all(["id in (?)",delete_ids])

    FinanceFeeParticular.add_or_remove_particular_or_discount(fd,fc)
  end

end

cp_with_school_ids=CollectionParticular.find_by_sql("SELECT distinct school_id as s_id from `collection_particulars` GROUP BY finance_fee_collection_id,finance_fee_particular_id HAVING count(collection_particulars.id)>1")
cp_with_school_ids.each do |cp_with_school_id|
  MultiSchool.current_school=School.find(cp_with_school_id.s_id)
  CollectionParticular.find(:all,:select=>"collection_particulars.*,group_concat(id) as all_ids",:group=>"finance_fee_collection_id,finance_fee_particular_id",:having=>"count(collection_particulars.id)>1").each do |cp|

    delete_ids=cp.all_ids.split(',').map{|f| f.to_i}-[cp.id]
    fc=FinanceFeeCollection.find(cp.finance_fee_collection_id)
    fp=FinanceFeeParticular.find(cp.finance_fee_particular_id)
    CollectionParticular.destroy_all(["id in (?)",delete_ids])

    FinanceFeeParticular.add_or_remove_particular_or_discount(fp,fc)

  end
end

fees=FinanceFee.find(:all,:group=>"finance_fees.fee_collection_id,finance_fees.student_id",:having=>"count(finance_fees.id) >1",:select=>"id,group_concat(id) all_ids",:skip_multischool=>true)
all_ids=fees.collect(&:all_ids).join(',').split(',').map{|f| f.to_i}
first_ids=fees.collect(&:id)
delete_ids=(all_ids-first_ids)
if FinanceTransaction.find(:all,:joins=>:fee_transactions,:conditions=>["fee_transactions.finance_fee_id in (?)",delete_ids],:skip_multischool=>true).empty?

  cnt=FinanceFee.delete_all(["id in (?)",delete_ids])
 

end

ActiveRecord::Migrator.migrate 'db/tmp'


