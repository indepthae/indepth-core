t = Time.now
collections_count = 0
collection_assignee_count = 0
i_sql = "INSERT INTO transport_fee_collection_assignments (`transport_fee_collection_id`, `assignee_type`, `assignee_id`, `school_id`, `created_at`, `updated_at`) VALUES "
valid_assignee_types = ["\'EmployeeDepartment\'", "\'Batch\'"]
tfca_insert = []
School.find_in_batches({:batch_size => 500}) do |schools|
  schools.each_with_index do |school, i|
    puts "processing school##{school.id}"
    MultiSchool.current_school = school
    TransportFeeCollection.find_in_batches({:batch_size => 500, :conditions => "tfca.id is null", 
        :joins => "LEFT JOIN transport_fee_collection_assignments tfca 
                                    ON tfca.transport_fee_collection_id = transport_fee_collections.id"}) do |collections|
      collections.each do |collection|
        collections_count = collections_count.next
        c_ts = collection.try(:created_at)
        tsc = c_ts.present? ? c_ts.strftime("%Y-%m-%d %H:%M:%S") : nil
        gp_tfs = collection.transport_fees.all(:select => "groupable_type, group_concat(groupable_id) AS g_ids", 
          :conditions => "groupable_type IS NOT NULL AND groupable_id IS NOT NULL AND 
                                    groupable_type in (#{valid_assignee_types.join(',')})", 
          :group => "groupable_type")          
        gp_tfs.each do |g_tfs|
          gp_ids = g_tfs.g_ids.split(",").uniq
          assignee_type = g_tfs.groupable_type
          gp_ids.each do |g_id|
            rec = "(#{collection.id}, '#{assignee_type}', #{g_id}, #{collection.school_id},"
            rec += tsc.present? ? "'#{tsc}', '#{tsc}')" : "NULL, NULL)"
            collection_assignee_count = collection_assignee_count.next
            tfca_insert << rec
            if tfca_insert.length == 500                
              #                tfca_insert.each_slice(500) do |recs|
              tcfa_i_sql = "#{i_sql}"
              tcfa_i_sql += tfca_insert.join(',')
              ActiveRecord::Base.connection.execute(tcfa_i_sql)
              tfca_insert = []
              #                end
            end
          end
        end
      end      
    end
  end
end
if tfca_insert.length > 0
  tcfa_i_sql = "#{i_sql}"
  tcfa_i_sql += tfca_insert.join(',')
  ActiveRecord::Base.connection.execute(tcfa_i_sql)
end
t2 = Time.now
puts "start at #{t}"
puts "end at #{t2}"
puts "processed #{collections_count} Transport Fee Collections "
puts "inserted #{collection_assignee_count} transport fee collection assignment records"