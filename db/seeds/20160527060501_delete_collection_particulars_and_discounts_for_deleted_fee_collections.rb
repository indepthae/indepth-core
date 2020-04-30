collection_particular_delete_sql="DELETE FROM collection_particulars WHERE collection_particulars.id IN
                                  (SELECT id FROM (SELECT `collection_particulars`.id FROM `collection_particulars`
                                  INNER JOIN `finance_fee_particulars` ON `finance_fee_particulars`.id = `collection_particulars`.finance_fee_particular_id
                                  left join fee_collection_batches cb on cb.finance_fee_collection_id=collection_particulars.finance_fee_collection_id and cb.batch_id=finance_fee_particulars.batch_id
                                  WHERE (cb.id is null))__active_record_temp)"
 ActiveRecord::Base.connection.execute(collection_particular_delete_sql)


collection_discounts_delete_sql="DELETE FROM collection_discounts WHERE collection_discounts.id IN
                                  (SELECT id FROM (SELECT `collection_discounts`.id FROM `collection_discounts`
                                  INNER JOIN `fee_discounts` ON `fee_discounts`.id = `collection_discounts`.fee_discount_id
                                  left join fee_collection_batches cb on cb.finance_fee_collection_id=collection_discounts.finance_fee_collection_id and cb.batch_id=fee_discounts.batch_id
                                  WHERE (cb.id is null))__active_record_temp)"
ActiveRecord::Base.connection.execute(collection_discounts_delete_sql)