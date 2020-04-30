HostelFeeCollection.find_by_sql("SELECT * FROM `hostel_fee_collections` GROUP BY start_date,end_date,name,due_date").each do |a|
    HostelFeeCollection.all(:conditions=>["name=? and  start_date='#{a.start_date}' and end_date='#{a.end_date}' and is_deleted=false and due_date='#{a.due_date}'",a.name],:skip_multischool=>true).each do |b|
    HostelFee.update_all({:hostel_fee_collection_id =>a.id},{:hostel_fee_collection_id=>b.id})
  end
end