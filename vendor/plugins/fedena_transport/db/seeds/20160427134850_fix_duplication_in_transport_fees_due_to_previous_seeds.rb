#For each school collections from other schools are updating to the collections with same name in the current school.

TransportFee.find(:all, :select => "transport_fees.*,transport_fees.school_id s_id,tfc.name collection_name,tfc.start_date,tfc.end_date,tfc.due_date",
                  :joins => "left join transport_fee_collections tfc on tfc.id=transport_fees.transport_fee_collection_id",
                  :conditions => "transport_fees.school_id<>tfc.school_id", :skip_multischool => true).each do |tf|

  tfc=TransportFeeCollection.find(:first, :conditions => ["name=? and start_date=? and due_date=? and end_date=? and is_deleted=false and school_id=?", tf.collection_name, tf.start_date, tf.due_date, tf.end_date, tf.s_id], :skip_multischool => true)
  ActiveRecord::Base.connection.execute("update transport_fees set transport_fee_collection_id='#{tfc.id}' where id=#{tf.id}")
end







# removing duplicate transport_fees that has no finance transaction and amount with same amount

tfs=TransportFee.find(:all, :select => "transport_fees.*,group_concat(if(transaction_id is null,id,null)) null_t_ids,group_concat(if(transaction_id is not null,id,null)) wt_ids,if(group_concat(if(transaction_id is not null,id,null)) is null,id,null) bm",
                      :conditions => "receiver_type='Student'", :group => "transport_fee_collection_id,receiver_id,bus_fare",
                      :having => "count(transport_fees.id)>1", :skip_multischool => true)

def arrayfi(a)
  a=a.join(',').split(',').map { |v| v.to_i }
  a.delete(0)
  a
end


x=arrayfi(tfs.collect(&:null_t_ids))

y=arrayfi(tfs.collect(&:bm))

del=(x-y).join(',')

ActiveRecord::Base.connection.execute("DELETE FROM `transport_fees` WHERE (id in(#{del}))") if del.present?








# updating transport_collection_id of duplicate transport_fees that has no finance transaction and difference in bus fare
tfs1=TransportFee.find(:all, :select => "transport_fees.*,group_concat(if(transaction_id is null,id,null)) null_t_ids,group_concat(if(transaction_id is not null,id,null)) wt_ids,if(group_concat(if(transaction_id is not null,id,null)) is null,id,null) bm",
                       :conditions => "receiver_type='Student'",
                       :group => "transport_fee_collection_id,receiver_id",
                       :having => "count(transport_fees.id)>1 and null_t_ids is not null", :skip_multischool => true)

updated_ids=[]

tfs1.each do |tf|

  tfcs=TransportFee.all(:select => "distinct tfcs.*",
                        :joins => "INNER JOIN `transport_fee_collections` ON `transport_fee_collections`.id = `transport_fees`.transport_fee_collection_id
                            left join transport_fee_collections tfcs on tfcs.name=transport_fee_collections.name",
                        :conditions => "transport_fees.id=#{tf.id} and tfcs.id > #{tf.transport_fee_collection_id} and tfcs.is_deleted=false", :skip_multischool => true).collect(&:id)

  update_ids=tf.null_t_ids.split(',').map { |v| v.to_i }-[tf.bm.to_i]


  update_ids.each do |upd|

    unless tfcs.empty?
      ActiveRecord::Base.connection.execute("update transport_fees set transport_fee_collection_id='#{tfcs.first}' where id=#{upd}")
      updated_ids << upd
      tfcs.delete(tfcs.first)
    end

  end

end
