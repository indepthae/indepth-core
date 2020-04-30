require 'logger'
start_time = Time.now
unless File.exist?("log/seed")
  FileUtils.mkpath "log/seed"
end
log = Logger.new("log/seed/finance_transaction_with_finance_donations-#{start_time.to_i}.log")

sql = "SELECT count(*) from finance_donations
   INNER JOIN finance_transactions ft ON ft.id = finance_donations.transaction_id
        WHERE ft.finance_id IS NULL AND ft.finance_type IS NULL"

log.info(sql)
res = ActiveRecord::Base.connection.execute(sql)

log.info("Before seed")
log.info(res.all_hashes)

sql = "UPDATE finance_transactions
   INNER JOIN finance_donations fd ON fd.transaction_id = finance_transactions.id
          SET finance_type = 'FinanceDonation', finance_id = fd.id
        WHERE finance_type IS NULL AND finance_id IS NULL"

log.info(sql)
ActiveRecord::Base.connection.execute(sql)

sql = "SELECT count(*) from finance_donations
   INNER JOIN finance_transactions ft ON ft.id = finance_donations.transaction_id
        WHERE ft.finance_id IS NULL AND ft.finance_type IS NULL"

log.info(sql)
res = ActiveRecord::Base.connection.execute(sql)

log.info("After seed")
log.info(res.all_hashes)


end_time = Time.now
log.info "execution time:"
log.info "Start : #{start_time}"
log.info  "End : #{end_time}"
log.info  "duration : #{(end_time - start_time).seconds}"


