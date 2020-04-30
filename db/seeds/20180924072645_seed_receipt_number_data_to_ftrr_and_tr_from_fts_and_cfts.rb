FeatureLock.lock_feature :finance_multi_receipt_data_updation
require 'logger'
School.active.each do |school|
  MultiSchool.current_school = school
  school_id = school.id #MultiSchool.current_school.id
  start_time = Time.now
  unless File.exist?("log/school_seeds/#{school_id}/")
    FileUtils.mkpath "log/school_seeds/#{school_id}/"
  end
  log = Logger.new("log/school_seeds/#{school_id}/generate_transaction_receipts-#{start_time.to_i}.log")

  log.info "School :: #{school_id} :: #{start_time}"
  log.info "Bulk insert transaction receipts from finance_transactions, cancelled_finance_transactions and finance_transaction_ledgers"

  tr_i_sql = "INSERT INTO transaction_receipts (school_id, receipt_sequence, receipt_number, ef_receipt_number) "
  tr_s_sql = " SELECT ftl.school_id,
                      IFNULL(SUBSTRING(IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no)), 1,
                             LENGTH(IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no))) -
                             LENGTH(REGEXP_SUBSTR(IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no)),'[0-9]*$'))),'') AS prefix,
                      REGEXP_SUBSTR(IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no)), '[0-9]*$') AS suffix,
                      IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no))"
  tr_f_sql = "            FROM finance_transaction_ledgers ftl"
  tr_j_sql = " left join finance_transactions ft ON ft.transaction_ledger_id = ftl.id
             left join cancelled_finance_transactions cft ON cft.transaction_ledger_id = ftl.id

             left join transaction_receipts tr
                    ON tr.ef_receipt_number = IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no)) AND
                       tr.school_id = #{school_id} "

  tr_w_sql = " where ftl.school_id = #{school_id} AND tr.id IS NULL"

  tr_g_sql = " group by IFNULL(ftl.receipt_no, IFNULL(ft.receipt_no, cft.receipt_no))"
  tr_h_sql = " having (suffix IS NOT NULL) OR CAST(suffix AS SIGNED) > 0"


  tr_sql = (tr_i_sql + tr_s_sql + tr_f_sql + tr_j_sql + tr_w_sql + tr_g_sql + tr_h_sql).squish

  begin
    ActiveRecord::Base.connection.execute(tr_sql)
  rescue Exception => e
    log.info e
  end

  precision_count = ((Configuration.get_config_value 'PrecisionCount') || 2).to_i

  log.info "Bulk insert finance_transaction_receipt_records from finance_transactions"

  ftrr_i_sql = "INSERT INTO finance_transaction_receipt_records (finance_transaction_id, school_id,
                                             precision_count, transaction_receipt_id) "
  ftrr_s_sql = "        SELECT transactions.id, transactions.school_id, #{precision_count}, tr.id "
  ftrr_f_sql = "           FROM finance_transactions transactions"

  ftrr_ftl_sql = " INNER JOIN finance_transaction_ledgers ftl
                                        ON ftl.id = transactions.transaction_ledger_id "
  ftrr_ftc_sql = " INNER JOIN finance_transaction_categories
                                         ON finance_transaction_categories.id = transactions.category_id "
  ftrr_ftrr_sql = " LEFT JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = transactions.id "
#ftrr_tr_sql = " INNER JOIN transaction_receipts tr
#                                        ON CONCAT(IFNULL(tr.receipt_sequence,''),tr.receipt_number) =
#                                              IFNULL(transactions.receipt_no,ftl.receipt_no) AND tr.school_id = ftl.school_id"
  ftrr_tr_sql = " INNER JOIN transaction_receipts tr
                                        ON tr.ef_receipt_number =
                                              IFNULL(transactions.receipt_no,ftl.receipt_no) AND tr.school_id = ftl.school_id"
  ftrr_w_sql = "       WHERE tr.id IS NOT NULL AND ftrr.id IS NULL AND
                                              finance_transaction_categories.is_income = 1 AND
                                              transactions.school_id = #{school_id}"

  ftrr_j_sql = ftrr_ftl_sql + ftrr_ftc_sql + ftrr_ftrr_sql + ftrr_tr_sql

  ftrr_sql = (ftrr_i_sql + ftrr_s_sql + ftrr_f_sql + ftrr_j_sql + ftrr_w_sql).squish

  begin
    ActiveRecord::Base.connection.execute(ftrr_sql)
  rescue Exception => e
    log.info e
  end

  log.info "Bulk insert finance_transaction_receipt_records from cancelled_finance_transactions"

  ftrr_s_sql = "        SELECT transactions.finance_transaction_id, transactions.school_id, #{precision_count}, tr.id "
  ftrr_f_sql = "           FROM cancelled_finance_transactions transactions"

  ftrr_w_sql = "       WHERE tr.id IS NOT NULL AND ftrr.id IS NULL AND
                                              finance_transaction_categories.is_income = 1 AND
                                              transactions.finance_transaction_id IS NOT NULL AND
                                              transactions.school_id = #{school_id}"
  ftrr_ftrr_sql = " LEFT JOIN finance_transaction_receipt_records ftrr
                                        ON ftrr.finance_transaction_id = transactions.finance_transaction_id "

  ftrr_j_sql = ftrr_ftl_sql + ftrr_ftc_sql + ftrr_ftrr_sql + ftrr_tr_sql

  ftrr_sql = (ftrr_i_sql + ftrr_s_sql + ftrr_f_sql + ftrr_j_sql + ftrr_w_sql).squish

  log.info ftrr_sql
  begin
    ActiveRecord::Base.connection.execute(ftrr_sql)
  rescue Exception => e
    log.info e
  end

  end_time = Time.now
  log.info "execution time:"
  log.info "Start : #{start_time}"
  log.info "End : #{end_time}"
  log.info "duration : #{(end_time - start_time).seconds}"
end

# remove feature access lock
file_name = "20180925072347_seed_new_fee_receipt_number_config_with_old_fee_receipt_config.rb"
sql = "SELECT * FROM record_updates where file_name like '%#{file_name}%'"
res = ActiveRecord::Base.connection.execute(sql)

if res.present? and res.all_hashes.present?
  lock_file_name = 'tmp/finance_multi_receipt_data_updation.featurelock'
  if File.exists?(lock_file_name)
    FileUtils.remove lock_file_name
  end
end
