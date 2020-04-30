class AddUniquenessForTransactionLedger < ActiveRecord::Migration
  def self.up

    FinanceTransactionLedger.reset_column_information
    unless FinanceTransactionLedger.column_names.include?("school_id")
      add_column :finance_transaction_ledgers, :school_id, :integer
      add_index :finance_transaction_ledgers, :school_id
    end
    receipt_duplicate_fix
    add_index :finance_transaction_ledgers, [:receipt_no, :school_id], :unique => true
   
  end

  def self.down
    remove_index :finance_transaction_ledgers, [:receipt_no, :school_id], :unique => true
  end
  
  
  private

  def self.receipt_duplicate_fix
    log = Logger.new("log/finance_ledger_duplicate.log")
    log.info("================STARTED ON #{Time.now}============")
    school_ids = FinanceTransactionLedger.find_by_sql("SELECT distinct school_id as s_id FROM `finance_transaction_ledgers` GROUP BY receipt_no,school_id HAVING count(receipt_no)>1;")
    log.info("================Total Schools #{school_ids.count}============")
    school_ids.each do |school_id|
      log.info("================School #{school_id.s_id} STARTED ON #{Time.now}============")
      MultiSchool.current_school= School.find_by_id(school_id.s_id)
      duplicate_recp_nos = FinanceTransactionLedger.find(:all,:select=>'distinct receipt_no as receipt',:group=>"receipt_no",:having=>"count(receipt_no)>1")
      log.info("==============DUPLICATE NUMBERS=======#{duplicate_recp_nos.collect(&:receipt)}============================================")
      duplicate_recp_nos.each do |receipt_no|
        ftl = FinanceTransactionLedger.find_all_by_receipt_no(receipt_no.receipt)
        ftl.each_with_index do |ledger, i|
          unless i == 0
            ledger.receipt_no = FinanceTransactionLedger.generate_receipt_no
            ledger.send(:update_without_callbacks)
            log.info("==RECIPT Number #{receipt_no.receipt} Changed to #{ledger.receipt_no}==")
          end
        end
      end
      log.info("================School #{school_id.s_id} COMPLETED ON #{Time.now}============")
      log.info("=============================================================================")
    end
  end
  
end
