require 'logger'
require 'fileutils'

log = Logger.new("log/nsq_finder_#{Time.now.to_i}.log")

# FileUtils.touch "tmp/finance_multi_receipt_data_updation.featurelock"

school_hash = Hash.new { |h, k| h[k] = Array.new(&h.default_proc) }
select_sql = "select
MAX(CAST(REGEXP_SUBSTR(IFNULL(IFNULL(ft.receipt_no,ftl.receipt_no),''),'[0-9]*$') AS SIGNED)) AS suffix,
SUBSTRING(IFNULL(ft.receipt_no,ftl.receipt_no), 1, LENGTH(IFNULL(ft.receipt_no,ftl.receipt_no)) -
LENGTH(REGEXP_SUBSTR(IFNULL(ft.receipt_no,ftl.receipt_no),'[0-9]*$'))) AS prefix, ft.school_id AS school_id "

join_sql = "INNER JOIN finance_transaction_ledgers ftl ON ftl.id = ft.transaction_ledger_id
            INNER JOIN schools s ON s.id = ft.school_id "
ft_from_sql = "from finance_transactions ft "
cft_from_sql = "from cancelled_finance_transactions ft "
c_sql = "WHERE (ft.voucher_no IS NULL AND s.is_deleted = 0) "

group_sql = "GROUP BY ft.school_id, prefix having suffix IS NOT NULL AND suffix > 0"

ft_sql = select_sql + ft_from_sql + join_sql + c_sql + group_sql
cft_sql = select_sql + cft_from_sql + join_sql + c_sql + group_sql

select_tr_sql = "SELECT MAX(CAST(tr.receipt_number AS SIGNED)) AS suffix, tr.receipt_sequence AS prefix, tr.school_id "
from_sql = "from transaction_receipts tr "
j_sql = " INNER JOIN schools s ON s.id = tr.school_id AND s.is_deleted = 0 "
group_tr_sql = "GROUP BY tr.school_id, prefix HAVING suffix is NOT NULL AND suffix > 0"
tr_sql = select_tr_sql + from_sql + j_sql + group_tr_sql

cft_res = ActiveRecord::Base.connection.execute(cft_sql).all_hashes
ft_res = ActiveRecord::Base.connection.execute(ft_sql).all_hashes

tr_res = ActiveRecord::Base.connection.execute(tr_sql).all_hashes

i = 0

tr_res.each do |row|
  school_id = row["school_id"].to_i
  prefix = row["prefix"]
  suffix = row["suffix"].to_i
  log.info("Processing school id :: #{school_id}; Prefix :: #{prefix}")
  school_hash[school_id] ||= []
  ft_rec = ft_res.select { |x| x["school_id"].to_i == school_id and x["prefix"] == prefix }
  log.info("Expected 1 row in finance transactions") if ft_rec.length > 1
  ft_suffix = ft_rec.present? ? ft_rec.collect { |x| x["suffix"].to_i } : [0]
  cft_rec = cft_res.select { |x| x["school_id"].to_i == school_id and x["prefix"] == prefix }
  log.info("Expected 1 row in transaction receipts") if cft_rec.length > 1
  cft_suffix = cft_rec.present? ? cft_rec.collect { |x| x["suffix"].to_i } : [0]

  max_value = ([suffix] + ft_suffix + cft_suffix).max

  hsh = {:ft_suffix_value => ft_suffix, :cft_suffix_value => cft_suffix, :correct_value => max_value,
         :prefix => prefix, :tr_suffix_mval => suffix}
  school_hash[school_id] << hsh #if max_value > 0 and max_value == suffix
  school_hash[school_id].compact!
  i = i.next
end

total_records_to_fix = 0
school_hash.each_pair { |s_id, recs| total_records_to_fix += recs.length }
filter_hash = Hash[school_hash.select { |sid, recs| recs.length > 0 }]

log.info(filter_hash.values.flatten.length)
k = 0
log.info("started update")
log.info(Time.now)
filter_hash.each_pair do |school_id, data_recs|
  log.info "school_id: #{school_id}"
  data_recs.each do |rec|
    log.info(rec)
    set_value = rec[:correct_value]
    puts set_value
    prefix = rec[:prefix]
    prefix_cond = (prefix.present? and prefix.length > 0) ? "AND name like '#{prefix}'" : "AND (LENGTH(name) = 0 AND name like '')"
    update_sql = "INSERT INTO `number_sequences`
                                                           (`name`, `sequence_type`, `next_number`, `created_at`,
                                                            `updated_at`, `school_id`)
                                              VALUES ('#{prefix}', 'receipt_no', #{set_value},
                                                             NOW(), NOW(), #{school_id})
              ON DUPLICATE KEY "
    update_sql += "UPDATE next_number = IF((@n := next_number) < #{set_value}, #{set_value}, next_number),
                          updated_at = IF(@n < #{set_value}, NOW(), updated_at)"
    log.info(update_sql)

    res = ActiveRecord::Base.connection.execute(update_sql)
  end
end
log.info(Time.now)
log.info("update ends")
log.info("Processed #{i} results.")
log.info("Data Report:")
log.info("------------")
log.info(Time.now)
# FileUtils.rm "tmp/finance_multi_receipt_data_updation.featurelock"