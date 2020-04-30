log = Logger.new('log/fix_transport_fee_collection_assignments.log')
t = Time.now
collections_count = 0
collection_assignee_count = 0
batch_missing_assignee_count = 0
dept_missing_assignee_count = 0
batch_wrong_assignee_count = 0
dept_wrong_assignee_count = 0
missing_in_school = 0
wrong_in_school = 0
total_new_inserts = 0
total_deletions = 0
i_sql = "INSERT INTO transport_fee_collection_assignments (`transport_fee_collection_id`, `assignee_type`, 
              `assignee_id`, `school_id`, `created_at`, `updated_at`) VALUES "
d_sql = "DELETE FROM transport_fee_collection_assignments WHERE " 
valid_assignee_types = ["\'EmployeeDepartment\'", "\'Batch\'"]
tfca_insert = []
School.find_in_batches({:batch_size => 500}) do |schools|
  schools.each_with_index do |school, i|
    log.info "processing school##{school.id}"
    log.info "----------------------------------------"
    MultiSchool.current_school = school
      
    existing_mappings = {}
      
    TransportFeeCollectionAssignment.find_in_batches({:batch_size => 500,           
        :select => "assignee_type, assignee_id, transport_fee_collection_id"        
      }) do |tfcas| 
      tfcas.each do |x|        
        existing_mappings[x.transport_fee_collection_id.to_s] ||= []
        existing_mappings[x.transport_fee_collection_id.to_s] << "#{x.assignee_type}_#{x.assignee_id}"        
      end
    end
      
    #all transport fees      
    TransportFee.find_in_batches({:batch_size => 500, 
        :select => "transport_fees.id, transport_fees.transport_fee_collection_id AS collection_id, tfc.created_at AS created_at,
                            transport_fees.groupable_type, transport_fees.groupable_id",
        :joins => "INNER JOIN transport_fee_collections tfc 
                                       ON tfc.id = transport_fees.transport_fee_collection_id",                    
        :conditions => "groupable_type IS NOT NULL AND groupable_id IS NOT NULL AND 
                                  groupable_type in (#{valid_assignee_types.join(',')})"
      }) do |transport_fees|
        
       
      transport_fees.each_with_index do |transport_fee, tf_idx|          
        record = "#{transport_fee.groupable_type}_#{transport_fee.groupable_id}"
        next if existing_mappings[transport_fee.collection_id.to_s].present? and 
          existing_mappings[transport_fee.collection_id.to_s].include?(record)
        collection_id = transport_fee.collection_id          
        if tfca_insert.length < 100
          rec = "(#{collection_id}, '#{transport_fee.groupable_type}', #{transport_fee.groupable_id}, #{school.id},"
          rec += transport_fee.created_at.present? ? "'#{transport_fee.created_at}', '#{transport_fee.created_at}')" : 
            "NULL, NULL)"
          tfca_insert << rec
          tfca_insert.uniq!
          if existing_mappings[transport_fee.collection_id.to_s].present?
            existing_mappings[transport_fee.collection_id.to_s] << record
            existing_mappings[transport_fee.collection_id.to_s].uniq!
          else 
            existing_mappings[transport_fee.collection_id.to_s] = [record]
          end
          missing_in_school += 1
          total_new_inserts += 1
        else
          tfca_i_sql = i_sql
          tfca_i_sql += tfca_insert.uniq.join(',')
          ActiveRecord::Base.connection.execute(tfca_i_sql)
          tfca_insert = []
        end
      end
      #        log.info("new records to insert: #{tfca_insert.length}")
      if tfca_insert.length > 0
        tfca_i_sql = i_sql
        tfca_i_sql += tfca_insert.join(',')
        ActiveRecord::Base.connection.execute(tfca_i_sql)
        tfca_insert = []
      end
        
    end
    TransportFeeCollection.find_in_batches({:batch_size => 500}) do |collections|
      wrong_mappings = []
      collections.each do |collection|
        batches = []
        depts = []
        TransportFee.find_in_batches({:batch_size => 500, 
            :conditions => {:transport_fee_collection_id => collection.id}}) do |fees|
          batches += fees.map {|x| x.groupable_id.to_i if x.groupable_type == 'Batch'}.uniq
          depts += fees.map {|x| x.groupable_id.to_i if x.groupable_type == 'EmployeeDepartment'}.uniq            
          #          batches += f  
        end
        all_batch_ids = Batch.all(:select => "id").map {|x| x.id.to_i }
        all_dept_ids = EmployeeDepartment.all(:select => "id").map {|x| x.id.to_i }
        batches.uniq!
        depts.uniq!
        new_wrong_mappings = (all_batch_ids - 
            batches).present? ? TransportFeeCollectionAssignment.all(            
          :conditions => ["transport_fee_collection_id = #{collection.id} AND 
                                    assignee_type = 'Batch' AND assignee_id NOT IN (?)", 
            (all_batch_ids - batches).uniq]) : []
        new_wrong_mappings += TransportFeeCollectionAssignment.all(
          :conditions => ["transport_fee_collection_id = #{collection.id} AND 
                                      assignee_type = 'EmployeeDepartment' AND assignee_id NOT IN (?)", (all_dept_ids - 
                depts).uniq]) if (all_dept_ids - depts).present?
          
        wrong_mappings += new_wrong_mappings
        wrong_in_school += new_wrong_mappings.length
      end
        
      if wrong_mappings.present?
        #          puts wrong_mappings.map {|x| x.assignee_id }.inspect
        #                    TransportFeeCollectionAssignment.delete_all(["id IN (?)", wrong_mappings.map(&:id)])
        total_deletions += wrong_mappings.length
      end
    end
      
    log.info("Missing in school id #{school.id} :: #{missing_in_school}")
    log.info("Wrong in school id #{school.id} :: #{wrong_in_school}")
    missing_in_school = 0
    wrong_in_school = 0
  end
end
t2 = Time.now
log.info "start at #{t}"
log.info "end at #{t2}"
log.info "processed #{collections_count} Transport Fee Collections "
log.info "inserted #{collection_assignee_count} transport fee collection assignment records"
log.info "Total insertions : #{total_new_inserts}"
log.info "Total deletions : #{total_deletions}"