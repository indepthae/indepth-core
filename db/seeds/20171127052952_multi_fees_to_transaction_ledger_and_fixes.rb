require 'logger'
date = Date.today
start_time = Time.now
log = Logger.new("log/finance_transaction_ledger_creation_log-#{date.to_s}.log")
total_schools = 0
total_multi_fee_records = 0
failed_multi_fee_records = 0
total_single_finance_transaction_records = 0
failed_single_finance_transaction_records = 0
total_cancelled_transaction_records = 0
failed_cancelled_transaction_records = 0
SCHOOL_RECORDS_SIZE = 500
RECORDS_SIZE = 1000
schools_batch = 0
School.find_in_batches(:batch_size => SCHOOL_RECORDS_SIZE) do |schools|  
  schools_batch = schools_batch.next
  total_schools += schools.length
  
  log.info("================")
  log.info("school batch : ##{schools_batch}")
  log.info("================")
  
  schools.each do |school|    
    log.info("================")
    log.info("school : ##{school.id}")
    log.info("================")
    MultiSchool.current_school = school
    # step : 1 ( move MultiFeesTransaction to FinanceTransactionLedger & link to respective finance_transaction records )
    log.info("========================================")
    log.info("Step :: 1 (copy multi fees records to finance transaction ledger")
    log.info("========================================")
    multi_fees_batch = 0
    MultiFeesTransaction.find_in_batches(:batch_size => RECORDS_SIZE, :include => :finance_transactions, 
      :joins => :finance_transactions, :conditions => "finance_transactions.transaction_ledger_id is null",
      :select => "DISTINCT multi_fees_transactions.*") do |multi_fees|
      multi_fees_batch = multi_fees_batch.next
      total_multi_fee_records += multi_fees.length
      
      log.info("==========================")
      log.info("multi fees batch : ##{multi_fees_batch}")
      log.info("==========================")
      
      multi_fees.each do |multi_fee|        
        transaction_ids = multi_fee.finance_transaction_ids
        if transaction_ids.present?
          ActiveRecord::Base.transaction do
            begin
              multi_fee_attributes = multi_fee.attributes.except("id","student_id")
              transaction_ledger = FinanceTransactionLedger.new(multi_fee_attributes)
              transaction_ledger.transaction_type = "MULTIPLE"
              transaction_ledger.transaction_mode = "MULTIPLE"
              transaction_ledger.status = "ACTIVE"
              transaction_ledger.payee_id = multi_fee.student_id
              transaction_ledger.payee_type = "Student" if multi_fee.student_id.present? 
              transaction_ledger.save!
              ActiveRecord::Base.connection.execute("UPDATE finance_transactions SET 
                  transaction_ledger_id = #{transaction_ledger.id} WHERE id in (#{transaction_ids.join(',')})")            
            rescue Exception => e
              
              failed_multi_fee_records += 1
              
              log.info "Error occurred : Details are"
              log.info "------------------------------------------"
              log.info e.inspect              
              log.info "multi_fees_transaction :; #{multi_fee.id}"
              log.info multi_fee.inspect
              log.info transaction_ledger.inspect
              log.info "finance_transaction_ledger :; #{transaction_ledger.id}"
              ActiveRecord::Rollback
              
            end
          end
        else
          log.info "no transactions linked to multi fee##{multi_fee.id}"
        end
      end
    end
    
    log.info("===================================================================================")
    log.info("Step :: 2 (create finance transaction ledger for finance transactions with no ledger records linked or are single finance transactions")
    log.info("===================================================================================")
    # step : 2 ( create FinanceTransactionLedger for individual finance_transaction records, and link with same )
    finance_transactions_batch = 0
    FinanceTransaction.find_in_batches(:batch_size => RECORDS_SIZE, 
      :conditions => "transaction_ledger_id is null", 
      :include => :multi_fees_transactions) do |transactions|
      finance_transactions_batch = finance_transactions_batch.next
      total_single_finance_transaction_records += transactions.length
      
      log.info("==========================")
      log.info("finance transactions batch : ##{finance_transactions_batch}")
      log.info("==========================")
      
      transactions.each do |transaction|
        unless transaction.multi_fees_transactions.present?
          ActiveRecord::Base.transaction do 
            begin
              transaction_ledger = FinanceTransactionLedger.new
              transaction_ledger.amount = transaction.amount
              transaction_ledger.payment_mode = transaction.payment_mode
              transaction_ledger.payment_note = transaction.payment_note
              transaction_ledger.transaction_date = transaction.transaction_date
              transaction_ledger.payee_id = transaction.payee_id
              transaction_ledger.payee_type = transaction.payee_type

              transaction_ledger.transaction_type = "SINGLE"
              transaction_ledger.status = "ACTIVE"
              transaction_ledger.transaction_mode = 'MULTIPLE'
              transaction_ledger.reference_no = transaction.reference_no
              # to ensure we dont loose information on when was transaction actually happened
              transaction_ledger.created_at = transaction.created_at
              transaction_ledger.updated_at = transaction.updated_at
              transaction_ledger.send(:create_without_callbacks) # to save without any callbacks
              #              transaction.update_attribute(:transaction_ledger_id, transaction_ledger.id)            
              transaction.transaction_ledger_id = transaction_ledger.id
              transaction.send(:update_without_callbacks) # to save without any callbacks
            rescue Exception => e
              
              failed_single_finance_transaction_records += 1
              
              log.info "Error occurred : Details are"
              log.info "------------------------------------------"
              log.info e.inspect              
              log.info "finance_transaction :; #{transaction.id}"
              log.info transaction.inspect
              log.info transaction_ledger.inspect
              log.info "finance_transaction_ledger :; #{transaction_ledger.id}"
              ActiveRecord::Rollback
              
            end
          end          
        else
          # add logic to handle finance transactions got left due to some reason from 
        end
      end
    end
    
    
    log.info("===================================================")
    log.info("Step :: 3 (create finance transaction ledger for cancelled finance transactions")
    log.info("===================================================")
    # step : 3 ( create FinanceTransactionLedger for individual cancelled_finance_transaction records, and link with same )
    cancelled_transactions_batch = 0
    CancelledFinanceTransaction.find_in_batches(:batch_size => RECORDS_SIZE, 
      :conditions => "transaction_ledger_id is null") do |transactions|
      cancelled_transactions_batch = cancelled_transactions_batch.next
      total_cancelled_transaction_records += transactions.length
      
      log.info("==========================")
      log.info("finance transactions batch : ##{cancelled_transactions_batch}")
      log.info("==========================")
      
      transactions.each do |transaction|
        ActiveRecord::Base.transaction do 
          begin
            transaction_ledger = FinanceTransactionLedger.new
            transaction_ledger.amount = transaction.amount
            transaction_ledger.payment_mode = transaction.payment_mode
            transaction_ledger.payment_note = transaction.payment_note
            transaction_ledger.transaction_date = transaction.transaction_date
            transaction_ledger.payee_id = transaction.payee_id
            transaction_ledger.payee_type = transaction.payee_type
          
            transaction_ledger.transaction_type = "SINGLE"
            transaction_ledger.status = "CANCELLED"
            transaction_ledger.transaction_mode = "MULTIPLE"
            transaction_ledger.reference_no = transaction.reference_no
            # to ensure we dont loose information on when was transaction actually happened
            transaction_ledger.created_at = transaction.created_at
            transaction_ledger.updated_at = transaction.updated_at
            transaction_ledger.send(:create_without_callbacks) # to save without any callbacks
            #            transaction.update_attribute(:transaction_ledger_id => transaction_ledger.id)
            transaction.transaction_ledger_id = transaction_ledger.id
            transaction.send(:update_without_callbacks) # to save without any callbacks
          rescue Exception => e
            
            failed_cancelled_transaction_records += 1
            
            log.info "Error occurred : Details are"
            log.info "------------------------------------------"
            log.info e.inspect
            log.info "cancelled finance_transaction :; #{transaction.id}"
            log.info transaction.inspect
            log.info transaction_ledger.inspect
            log.info "finance_transaction_ledger :; #{transaction_ledger.id}"
            ActiveRecord::Rollback
            
          end
        end
        
      end
    end
  end
end
end_time = Time.now
log.info("==========")
log.info("Seed summary:")
log.info("==========")
log.info("Total schools : #{total_schools}")
log.info("Total multi fees records : #{total_multi_fee_records}")
log.info("Failed multi fees records : #{failed_multi_fee_records}")
log.info("Total single finance transaction records : #{total_single_finance_transaction_records}")
log.info("Failed transaction records : #{failed_single_finance_transaction_records}")
log.info("Total cancelled transaction records : #{total_cancelled_transaction_records}")
log.info("Failed cancelled transaction records : #{failed_cancelled_transaction_records}")
log.info("Seed start time : #{start_time}")
log.info("Seed end time : #{end_time}")
log.info("#{end_time - start_time} seconds")