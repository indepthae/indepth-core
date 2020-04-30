table_name = "user_events"
joins = []
joins << "INNER JOIN students ON students.user_id = user_events.user_id"
joins << "INNER JOIN transport_fees ON transport_fees.receiver_id = students.id AND transport_fees.transaction_id IS NOT NULL"
joins << "INNER JOIN events ON events.id =user_events.event_id"
joins << "INNER JOIN transport_fee_collections ON transport_fee_collections.id = events.origin_id AND transport_fee_collections.id = transport_fees.transport_fee_collection_id"
condition = ""
if defined? MultiSchool
  condition = " WHERE #{table_name}.school_id is not NULL" if MultiSchool.multi_school_models.include? table_name.classify
end
sql = "DELETE #{table_name}.* FROM #{table_name} #{joins.join(' ')} #{condition}"
ActiveRecord::Base.connection.execute(sql)
